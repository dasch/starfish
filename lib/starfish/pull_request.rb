module Starfish
  class PullRequest
    attr_reader :number, :title, :author, :pipeline

    def initialize(number:, title:, author:, pipeline:)
      @number = number
      @title = title
      @author = author
      @pipeline = pipeline
    end
  end
end
