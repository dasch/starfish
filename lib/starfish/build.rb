require 'starfish/status'

module Starfish
  class Build
    class Null
      def number
        0
      end
    end

    include Comparable

    attr_reader :id, :number, :author, :commits, :statuses, :pipeline, :approved_by
    attr_accessor :pull_request

    def initialize(id:, number:, author:, commits:, pipeline:)
      @id = id
      @number = number
      @author = author
      @commits = commits
      @pipeline = pipeline
      @approved_by = nil
      @statuses = []
    end

    def sha
      commit && commit.sha
    end

    def approved?
      !@approved_by.nil?
    end

    def approve!(user:)
      @approved_by = user
    end

    def update_status(name:, value:, description:, timestamp:)
      status = @statuses.find {|s| s.name == name }

      if status.nil?
        status = Status.new(name: name, created_at: timestamp)
        @statuses << status
      end

      status.update(value, description: description, timestamp: timestamp)

      status
    end

    def summary
      commit.summary
    end

    def changes
      commits.each_with_object({}) do |commit, changes|
        commit.added.each do |filename|
          if changes[filename] == :removed
            changes.delete(filename)
          else
            changes[filename] = :added
          end
        end

        commit.removed.each do |filename|
          if changes[filename] == :added
            changes.delete(filename)
          else
            changes[filename] = :removed
          end
        end

        commit.modified.each do |filename|
          if changes[filename] != :added
            changes[filename] = :modified
          end
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
