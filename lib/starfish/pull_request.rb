module Starfish
  class PullRequest
    attr_reader :number, :title, :author, :pipeline

    def initialize(number:, title:, author:, pipeline:)
      @number = number
      @title = title
      @author = author
      @pipeline = pipeline
      @status = :open
    end

    def close!
      @status = :closed
    end

    def to_s
      "##{number} #{title}"
    end
  end
end
