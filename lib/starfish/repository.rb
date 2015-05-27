require 'starfish/project'

module Starfish
  class Repository
    attr_reader :projects

    def initialize
      @projects = []
    end

    def add_project(**options)
      project = Project.new(**options)
      @projects << project
      project
    end

    def find_project(slug:)
      projects.find {|p| p.slug == slug }
    end
  end
end
