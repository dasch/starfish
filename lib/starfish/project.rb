require 'starfish/pipeline'
require 'starfish/commit'

module Starfish
  class Project
    attr_reader :name, :commits, :pipelines

    def initialize(name:)
      @name = name
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

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end
end
