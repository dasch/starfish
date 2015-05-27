module Starfish
  class Commit
    attr_reader :sha, :author, :message

    def initialize(sha:, author:, message: "N/A")
      @sha = sha
      @author = author
      @message = message
    end

    def to_s
      sha
    end
  end
end
