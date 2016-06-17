require 'starfish/project'
require 'starfish/not_found'

module Starfish
  class Repository
    def initialize
      @projects = {}
      @projects_by_slug = {}
    end

    def clear
      @projects.clear
    end

    def projects
      @projects.values
    end

    def add_project(**options)
      project = Project.new(**options)

      @projects[project.id] = project
      @projects_by_slug[project.slug] = project

      project
    end

    def find_project_by_slug(slug)
      @projects_by_slug.fetch(slug) { raise NotFound }
    end

    def find_project(id)
      @projects.fetch(id) { raise NotFound }
    end
  end
end
