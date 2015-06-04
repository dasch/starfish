require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    attr_reader :event_id, :event, :project, :payload

    post '/github/:project' do
      @event_id = env["HTTP_X_GITHUB_DELIVERY"]
      @event = env["HTTP_X_GITHUB_EVENT"]
      @project = $repo.find_project_by_slug(params[:project])
      @payload = JSON.parse(request.body.read)

      $stderr.puts "Handling #{event} webhook from GitHub"

      if respond_to?("#{@event}_received")
        send("#{@event}_received")
      end

      status 200
    end

    def push_received
      $events.record(:github_push_received, {
        event_id: event_id,
        project_id: project.id,
        payload: {
          "ref" => payload.fetch("ref"),
          "commits" => payload.fetch("commits"),
          "sender" => payload.fetch("sender"),
        }
      })
    end

    def pull_request_received
      $events.record(:github_pull_request_received, {
        event_id: event_id,
        project_id: project.id,
        payload: {
          "action" => payload.fetch("action"),
          "pull_request" => payload.fetch("pull_request"),
        }
      })
    end

    def status_received
      $events.record(:github_status_received, {
        event_id: event_id,
        project_id: project.id,
        payload: {
          "state" => payload.fetch("state"),
          "sha" => payload.fetch("sha"),
          "target_url" => payload.fetch("target_url"),
          "context" => payload.fetch("context"),
          "description" => payload.fetch("description"),
        }
      })
    end
  end
end
