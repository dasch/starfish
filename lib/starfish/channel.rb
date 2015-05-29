require 'starfish/release'
require 'starfish/config'

module Starfish
  class Channel
    attr_reader :id, :pipeline, :name, :releases, :configs

    def initialize(id: SecureRandom.uuid, pipeline:, name:, auto_release_builds: false)
      @id = id
      @pipeline = pipeline
      @name = name
      @releases = []
      @configs = [Config::Null.new]
      @auto_release_builds = auto_release_builds
    end

    def current_release
      releases.last
    end

    def current_build
      current_release ? current_release.build : Build::Null.new
    end

    def current_config
      configs.last
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

    def add_config_key(key, value)
      env = current_config.env.merge(key => value)
      add_config(env: env)
    end

    def find_config(version:)
      @configs.find {|c| c.version == version }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
