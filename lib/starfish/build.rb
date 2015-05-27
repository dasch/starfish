require 'starfish/status'

module Starfish
  class Build
    include Comparable

    attr_reader :number, :author, :commits, :statuses, :image, :pipeline

    def initialize(number:, author:, commits:, image: nil, pipeline:)
      @number = number
      @image = image
      @author = author
      @commits = commits
      @pipeline = pipeline
      @statuses = []
    end

    def approved?
      true
    end

    def add_status(name:, value:)
      status = Status.new(name: name, value: value)
      @statuses << status
      status
    end

    def status
      if statuses.all?(&:ok?)
        :ok
      elsif statuses.any?(&:pending?)
        :pending
      elsif statuses.any?(&:failed?)
        :failed
      else
        raise "what now?"
      end
    end

    def ok?
      status == :ok
    end

    def failed?
      status == :failed
    end

    def pending?
      status == :pending
    end

    def commit
      commits.last
    end

    def authors
      commits.flat_map(&:author).uniq
    end

    def <=>(other)
      number <=> other.number
    end

    def to_s
      "##{number}"
    end
  end
end
