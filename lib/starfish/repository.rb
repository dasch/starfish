require 'redis'
require 'starfish/project'

module Starfish
  class Repository
    attr_reader :projects

    def initialize
      @redis = Redis.new
      @projects = []
    end

    def add_project(**options)
      project = Project.new(**options)
      @projects << project
      project
    end

    def find_project_by_slug(slug)
      projects.find {|p| p.slug == slug }
    end

    def find_project(id)
      projects.find {|p| p.id == id }
    end
  end
end
