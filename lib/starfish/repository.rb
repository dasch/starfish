require 'starfish/project'
require 'starfish/not_found'

module Starfish
  class Repository
    attr_reader :projects

    def initialize
      @projects = []
    end

    def clear
      @projects.clear
    end

    def add_project(**options)
      project = Project.new(**options)
      @projects << project
      project
    end

    def find_project_by_slug(slug)
      projects.find {|p| p.slug == slug } or raise NotFound
    end

    def find_project(id)
      projects.find {|p| p.id == id } or raise NotFound
    end
  end
end
