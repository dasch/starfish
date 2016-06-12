require 'starfish/project'
require 'starfish/environment'
require 'starfish/not_found'

module Starfish
  class Repository
    attr_reader :projects, :environments

    def initialize
      @projects = []
      @environments = []
    end

    def clear
      @projects.clear
      @environments.clear
    end

    def add_project(**options)
      project = Project.new(**options)
      @projects << project
      project
    end

    def add_environment(**options)
      environment = Environment.new(**options)
      @environments << environment
      environment
    end

    def find_project_by_slug(slug)
      projects.find {|p| p.slug == slug } or raise NotFound
    end

    def find_project(id)
      projects.find {|p| p.id == id } or raise NotFound
    end

    def find_environment_by_name(name)
      environments.find {|e| e.name == name }
    end
  end
end
