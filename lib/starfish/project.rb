require 'starfish/pipeline'
require 'starfish/commit'

module Starfish
  class Project
    attr_reader :name, :repo, :commits, :pipelines

    def initialize(name:, repo: nil)
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

    def add_pipeline(**options)
      pipeline = Pipeline.new(**options.merge(project: self))
      @pipelines << pipeline
      pipeline
    end

    def find_pipeline(slug:)
      @pipelines.find {|b| b.slug == slug }
    end

    def find_pipelines(branch:)
      @pipelines.select {|p| p.branch == branch }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
