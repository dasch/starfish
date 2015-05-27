module Starfish
  class Release
    attr_reader :build, :config, :number, :channel

    def initialize(build:, config:, number:, channel:, author: nil)
      @build, @config, @number = build, config, number
      @channel = channel
      @author = author
    end

    def author
      @author || build.author
    end

    def authors
      build.authors
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
