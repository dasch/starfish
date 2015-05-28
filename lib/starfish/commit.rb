module Starfish
  class Commit
    attr_reader :sha, :author, :message, :added, :removed, :modified

    def initialize(sha:, author:, message: "N/A", added:, removed:, modified:)
      @sha = sha
      @author = author
      @message = message
      @added = added
      @removed = removed
      @modified = modified
    end

    def to_s
      sha
    end
  end
end
