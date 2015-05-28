require 'starfish/status'

module Starfish
  class Build
    class Null
      def number
        0
      end
    end

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

    def changes
      commits.each_with_object({}) do |commit, changes|
        commit.added.each do |filename|
          changes[filename] = :added
        end

        commit.removed.each do |filename|
          changes[filename] = :removed
        end

        commit.modified.each do |filename|
          changes[filename] = :modified
        end
      end
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
