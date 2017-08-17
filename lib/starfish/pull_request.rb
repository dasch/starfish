module Starfish
  class PullRequestReview
    attr_reader :state, :reviewer

    def initialize(state:, reviewer:)
      @state = state
      @reviewer = reviewer
    end

    def approved?
      @state == "approved"
    end

    def changes_requested?
      @state == "changes_requested"
    end
  end

  class PullRequest
    attr_reader :number, :title, :author, :pipeline, :reviews

    def initialize(number:, title:, author:, pipeline:)
      @number = number
      @title = title
      @author = author
      @pipeline = pipeline
      @status = :open
      @reviews = []
    end

    def add_review(state:, reviewer:)
      @reviews << PullRequestReview.new(state: state, reviewer: reviewer)
    end

    def approved?
      reviews.any? && reviews.all?(&:approved?)
    end

    def reviewers
      reviews.map(&:reviewer)
    end

    def close!
      @status = :closed
    end

    def to_s
      "##{number} #{title}"
    end
  end
end
