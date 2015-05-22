module Starfish
  class Release
    attr_reader :build, :config, :number, :channel

    def initialize(build:, config:, number:, channel:, previous_release:)
      @build, @config, @number, @channel = build, config, number, channel
      @previous_release = previous_release
    end

    def authors
      build.authors
    end

    def author
      authors.first
    end

    def new_build?
      @previous_release.nil? || @previous_release.build != build
    end

    def new_config?
      @previous_release.nil? || @previous_release.config != config
    end

    def to_s
      "v#{number}"
    end
  end
end
