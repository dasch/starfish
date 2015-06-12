require 'starfish/base_aggregate'

module Starfish
  class ProjectAggregate < BaseAggregate
    def initialize
      @pipelines = {}
    end

    def apply(event)
      case event.name
      when :project_added
        @id = event.aggregate_id
        puts "Created project #{@id}"
      when :pipeline_added
        pipelines[event.data.fetch(:branch)] = event.data.fetch(:pipeline_id)
      end
    end

    def add_project(name:, repo:)
      raise if name.empty? || repo.empty?
      raise unless id.nil?

      id = SecureRandom.uuid

      commit(:project_added, {
        aggregate_id: id,
        name: name,
        repo: repo
      })

      id
    end

    def add_pipeline(name:, branch:)
      raise if id.nil?
      raise if name.empty? || branch.empty?
      raise if pipeline_for_branch?(branch)

      pipeline_id = SecureRandom.uuid

      commit(:pipeline_added, {
        pipeline_id: pipeline_id,
        name: name,
        branch: branch
      })

      pipeline_id
    end

    def add_channel(name:, auto_release_builds:, pipeline_id:)
      raise if id.nil?
      raise if pipeline_id.nil?
      raise unless pipelines.values.include?(pipeline_id)

      channel_id = SecureRandom.uuid

      commit(:channel_added, {
        channel_id: channel_id,
        pipeline_id: pipeline_id,
        name: name,
        auto_release_builds: auto_release_builds
      })

      channel_id
    end

    def add_build(branch:, commits:, author:)
      raise if id.nil?
      raise if commits.empty?
      raise unless pipeline_for_branch?(branch)

      commit(:build_added, {
        build_id: SecureRandom.uuid,
        branch: branch,
        pipeline_id: pipelines.fetch(branch),
        commits: commits,
        author: author
      })
    end

    private

    attr_reader :pipelines

    def pipeline_for_branch?(branch)
      pipelines.include?(branch)
    end
  end
end
