module Starfish
  class Release
    attr_reader :build, :config, :number, :channel

    def initialize(build:, config:, number:, channel:)
      @build, @config, @number, @channel = build, config, number, channel
    end

    def authors
      build.authors
    end

    def to_s
      "v#{number}"
    end
  end
end
