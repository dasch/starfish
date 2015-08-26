module Starfish
  class Release
    attr_reader :id, :build, :config, :number, :channel, :event, :timestamp

    def initialize(id: SecureRandom.uuid, build:, config:, number:, channel:, author:, event:, timestamp:)
      @id = id
      @build = build
      @config = config
      @number = number
      @channel = channel
      @author = author
      @event = event
      @timestamp = timestamp
    end

    def event_name
      event.class.to_s.split("::").last.gsub(/\B([A-Z])/, '_\1').downcase.to_sym
    end

    def author
      @author || build.author
    end

    def authors
      build.authors
    end

    def to_s
      "v#{number}"
    end
  end
end
