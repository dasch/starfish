require 'starfish/channel'
require 'starfish/build'
require 'starfish/pull_request'

module Starfish
  class Pipeline
    attr_reader :id, :name, :project, :branch, :builds, :channels, :pull_requests

    def initialize(id: SecureRandom.uuid, name:, branch:, project:)
      @id = id
      @name = name
      @branch = branch
      @project = project
      @builds = []
      @channels = []
      @pull_requests = []
    end

    def add_build(**options)
      number = @builds.count + 1
      build = Build.new(**options.merge(pipeline: self, number: number))
      @builds << build

      channels.each do |channel|
        if channel.auto_release_builds?
          channel.add_release(
            id: SecureRandom.uuid,
            build: build,
            config: channel.current_config,
            author: build.author,
            event: :new_build
          )
        end
      end

      build
    end

    def find_build(number:)
      @builds.find {|b| b.number == number }
    end

    def find_builds_by_sha(sha)
      @builds.find_all {|b| b.sha == sha }
    end

    def add_channel(**options)
      channel = Channel.new(**options.merge(pipeline: self))
      @channels << channel
      channel
    end

    def releases
      @channels.flat_map(&:releases).sort_by(&:number)
    end

    def find_channel(id)
      @channels.find {|c| c.id == id }
    end

    def find_channel_by_slug(slug)
      @channels.find {|c| c.slug == slug }
    end

    def releases_for_build(build)
      @channels.find_all {|c| c.current_build == build }.map(&:current_release)
    end

    def add_pull_request(**options)
      pull_request = PullRequest.new(**options.merge(pipeline: self))
      @pull_requests << pull_request
      pull_request
    end

    def remove_pull_request(number)
      @pull_requests.delete_if {|pr| pr.number == number }
    end

    def find_pull_request(number)
      @pull_requests.find {|pr| pr.number == number }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
