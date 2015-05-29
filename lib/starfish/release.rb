module Starfish
  class Release
    attr_reader :id, :build, :config, :number, :channel, :event

    def initialize(id: SecureRandom.uuid, build:, config:, number:, channel:, author:, event:)
      @id = id
      @build = build
      @config = config
      @number = number
      @channel = channel
      @author = author
      @event = event
    end

    def author
      @author || build.author
    end

    def authors
      build.authors
    end

    def new_build?
      event == :new_build
    end

    def new_config?
      event == :new_config
    end

    def to_s
      "v#{number}"
    end
  end
end
