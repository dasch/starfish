require 'starfish/release'
require 'starfish/config'

module Starfish
  class Channel
    attr_reader :pipeline, :name, :releases, :configs

    def initialize(pipeline:, name:, auto_release_builds: false)
      @pipeline = pipeline
      @name = name
      @releases = []
      @configs = []
      @auto_release_builds = auto_release_builds
    end

    def current_release
      releases.last
    end

    def current_build
      current_release ? current_release.build : Build::Null.new
    end

    def current_config
      configs.last || Config::Null.new
    end

    def auto_release_builds?
      @auto_release_builds
    end

    def add_release(**options)
      number = @releases.count + 1
      release = Release.new(**options.merge(channel: self, number: number))
      @releases << release
      release
    end

    def find_release(number:)
      @releases.find {|b| b.number == number }
    end

    def add_config(**options)
      config = Config.new(**options.merge(version: @configs.count + 1))
      @configs << config
      config
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
