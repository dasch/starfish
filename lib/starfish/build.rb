require 'starfish/status_check'
require 'starfish/build_status'
require 'starfish/docker_build'

module Starfish
  class Build
    class Null
      def number
        0
      end
    end

    include Comparable

    attr_reader :id, :number, :author, :commits, :status_checks, :pipeline
    attr_accessor :pull_request, :docker_builds

    def initialize(id:, number:, author:, commits:, pipeline:)
      @id = id
      @number = number
      @author = author
      @commits = commits
      @pipeline = pipeline
      @status_checks = []
      @docker_builds = []
    end

    def sha
      commit && commit.sha
    end

    def update_status(context:, value:, url:, description:, timestamp:)
      status = @status_checks.find {|s| s.context == context }

      if status.nil?
        status = StatusCheck.new(context: context, url: url, created_at: timestamp)
        @status_checks << status
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

    def add_docker_build(**options)
      @docker_builds << DockerBuild.new(**options)
    end

    def status
      BuildStatus.new(status_checks)
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
