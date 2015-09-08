require 'octokit'
require 'faraday/http_cache'
require 'starfish/github_event_handlers'

module Starfish
  class GithubEventImporter
    GITHUB_CLIENT_ID = ENV.fetch("GITHUB_CLIENT_ID")
    GITHUB_CLIENT_SECRET = ENV.fetch("GITHUB_CLIENT_SECRET")

    def initialize(repo:, event_store:)
      stack = Faraday::RackBuilder.new do |builder|
        builder.use Faraday::HttpCache
        builder.use Octokit::Response::RaiseError
        builder.adapter Faraday.default_adapter
      end

      @github = Octokit::Client.new(
        client_id: GITHUB_CLIENT_ID,
        client_secret: GITHUB_CLIENT_SECRET,
        middleware: stack,
      )

      @repo = repo
      @last_event_ids = {}
      @event_store = event_store
      @event_handlers = GithubEventHandlers.new(@event_store)
    end

    def update_last_event_id(project_id:, event_id:)
      @last_event_ids[project_id] = event_id
    end

    def start
      while true
        puts "polling all projects..."

        @repo.projects.each do |project|
          last_event_id = @last_event_ids[project.id]

          puts "polling github events for #{project}, starting at #{last_event_id}..."

          events, event_id = poll(project, last_event_id)

          puts "got #{events.count} events; last id: #{event_id}"

          events.each do |event|
            puts "handling event #{event.type}..."
            @event_handlers.handle(project, event)
          end

          if event_id != last_event_id
            @event_store.record(:github_events_synchronized, {
              project_id: project.id,
              github_event_id: event_id,
            })
          end
        end

        sleep 10
      end
    end

    private

    def poll(project, last_event_id)
      if last_event_id.nil?
        last_event_id = @github.repository_events(project.repo).first.id
        return [[], last_event_id]
      end

      events = []

      @github.repository_events(project.repo).each do |event|
        break if event.id == last_event_id
        events.unshift(event)
      end

      # Newest event.
      last_event_id = events.empty? ? last_event_id : events.last.id

      [events, last_event_id]
    end
  end
end
