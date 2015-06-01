require 'starfish/channel'
require 'starfish/build'
require 'starfish/pull_request'
require 'starfish/not_found'
require 'starfish/automatic_release_event'

module Starfish
  class Pipeline
    attr_reader :id, :name, :project, :branch, :builds, :channels, :pull_requests
    attr_reader :notification_targets

    def initialize(id: SecureRandom.uuid, name:, branch:, project:)
      @id = id
      @name = name
      @branch = branch
      @project = project
      @builds = []
      @channels = []
      @pull_requests = []
      @notification_targets = []
    end

    def add_build(**options)
      number = @builds.count + 1
      build = Build.new(**options.merge(pipeline: self, number: number))
      @builds << build
      build
    end

    def find_build(number:)
      @builds.find {|b| b.number == number } or raise NotFound
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
      @channels.find {|c| c.id == id } or raise NotFound
    end

    def find_channel_by_slug(slug)
      @channels.find {|c| c.slug == slug } or raise NotFound
    end

    def channel_for_pod(pod)
      @channels.find {|c| c.name == pod }
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
      @pull_requests.find {|pr| pr.number == number } or raise NotFound
    end

    def config_keys
      @channels.map(&:current_config).flat_map(&:keys).uniq
    end

    def add_notification_target(target)
      @notification_targets << target
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
