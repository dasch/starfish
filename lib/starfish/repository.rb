require 'starfish/project'

module Starfish
  class Repository
    attr_reader :projects

    def initialize
      @projects = []
    end

    def add_project(name:)
      project = Project.new(name: name)
      @projects << project
      project
    end

    def find_project(slug:)
      projects.find {|p| p.slug == slug }
    end
  end
end
