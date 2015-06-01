require 'starfish/project'
require 'starfish/not_found'

module Starfish
  class Environment
    attr_reader :name, :pods

    def initialize(name:)
      @name = name
      @pods = []
    end

    def add_pod(name:)
      @pods << name
    end

    def slug
      name.downcase
    end

    def to_s
      name
    end
  end

  class Repository
    attr_reader :projects, :environments

    def initialize
      @projects = []

      @environments = []

      master = Environment.new(name: "Master")
      %w[Pod98 Pod99].each {|pod| master.add_pod(name: pod) }

      staging = Environment.new(name: "Staging")
      %w[Pod100 Pod101].each {|pod| staging.add_pod(name: pod) }

      production = Environment.new(name: "Production")
      %w[Pod1 Pod2 Pod3 Pod4 Pod5 Pod6].each {|pod| production.add_pod(name: pod) }

      @environments << master << staging << production
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

    def find_environment_by_slug(slug)
      @environments.find {|e| e.slug == slug } or raise NotFound
    end
  end
end
