module Starfish
  class Release
    attr_reader :id, :build, :config, :number, :channel, :message

    def initialize(id: SecureRandom.uuid, build:, config:, number:, channel:, author:, message:)
      @id = id
      @build = build
      @config = config
      @number = number
      @channel = channel
      @author = author
      @message = message
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
