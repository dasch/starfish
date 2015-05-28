module Starfish
  class PullRequest
    attr_reader :number, :title

    def initialize(number:, title:)
      @number = number
      @title = title
    end
  end
end
