require 'starfish/base_aggregate'

module Starfish
  class ProjectAggregate < BaseAggregate
    def initialize
      @id = nil
      @pipelines = {}
    end

    def apply(event)
      case event.name
      when :project_added
        @id = event.aggregate_id
      when :pipeline_added
        pipeline_branches[event.data.fetch(:branch)] = event.data.fetch(:pipeline_id)
      end
    end

    def add_project(name:, repository:)
      raise if name.empty? || repository.empty?
      raise unless id.nil?

      commit(:project_added, {
        name: name,
        repository: repository
      })
    end

    def add_pipeline(name:, branch:)
      raise if id.nil?
      raise if name.empty? || branch.empty?
      raise if pipeline_for_branch?(branch)

      commit(:pipeline_added, {
        pipeline_id: SecureRandom.uuid,
        name: name,
        branch: branch
      })
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
      pipeline_branches.include?(branch)
    end
  end
end
