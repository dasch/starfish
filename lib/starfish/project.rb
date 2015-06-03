require 'starfish/pipeline'
require 'starfish/commit'
require 'starfish/not_found'

module Starfish
  class Project
    attr_reader :id, :name, :repo, :commits, :pipelines

    def initialize(id:, name:, repo: nil)
      @id = id
      @name = name
      @repo = repo
      @pipelines = []
      @commits = []
    end

    def add_commit(**options)
      commit = Commit.new(**options)
      @commits << commit
      commit
    end

    def find_builds_by_sha(sha)
      pipelines.flat_map {|p| p.find_builds_by_sha(sha) }
    end

    def add_pipeline(**options)
      pipeline = Pipeline.new(**options.merge(project: self))
      @pipelines << pipeline
      pipeline
    end

    def find_pipeline(id)
      @pipelines.find {|b| b.id == id } or raise NotFound
    end

    def find_pipeline_by_slug(slug)
      @pipelines.find {|p| p.slug == slug } or raise NotFound
    end

    def find_pipeline_by_branch(branch)
      @pipelines.find {|p| p.branch == branch } or raise NotFound
    end

    def has_pipeline_for_branch?(branch)
      @pipelines.any? {|p| p.branch == branch }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
