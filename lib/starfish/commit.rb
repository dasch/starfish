module Starfish
  class Commit
    attr_reader :sha, :author, :message, :added, :removed, :modified, :url

    def initialize(sha:, author:, message: "N/A", added:, removed:, modified:, url:)
      @sha = sha
      @author = author
      @message = message
      @added = added
      @removed = removed
      @modified = modified
      @url = url
    end

    def summary
      message.split("\n").first
    end

    def to_s
      sha
    end
  end
end
