require 'starfish/release'
require 'starfish/config'

module Starfish
  class Channel
    attr_reader :pipeline, :name, :releases, :configs

    def initialize(pipeline:, name:)
      @pipeline = pipeline
      @name = name
      @releases = []
      @configs = []
    end

    def current_release
      releases.last
    end

    def current_build
      current_release.build
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
      config = Config.new(**options)
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