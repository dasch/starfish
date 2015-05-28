require 'starfish/channel'
require 'starfish/build'

module Starfish
  class Pipeline
    attr_reader :id, :name, :project, :branch, :builds, :channels

    def initialize(id: SecureRandom.uuid, name:, branch:, project:)
      @id = id
      @name = name
      @branch = branch
      @project = project
      @builds = []
      @channels = []
    end

    def add_build(**options)
      number = @builds.count + 1
      build = Build.new(**options.merge(pipeline: self, number: number))
      @builds << build

      channels.each do |channel|
        if channel.auto_release_builds?
          channel.add_release(
            build: build,
            config: channel.current_config,
            author: build.author
          )
        end
      end

      build
    end

    def find_build(number:)
      @builds.find {|b| b.number == number }
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

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
