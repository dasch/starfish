module Starfish
  class Commit
    attr_reader :sha, :author, :additions, :deletions

    def initialize(sha:, author:, additions:, deletions:)
      @sha = sha
      @author = author
      @additions = additions
      @deletions = deletions
    end

    def to_s
      sha
    end
  end
end
