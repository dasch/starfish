require 'starfish/project'
require 'starfish/not_found'

module Starfish
  class Pod
    attr_reader :number

    def initialize(number:)
      @number = number
    end

    def name
      "Pod#{number}"
    end

    def to_s
      name
    end
  end

  class Environment
    attr_reader :name, :pods

    def initialize(name:)
      @name = name
      @pods = []
    end

    def add_pod(**options)
      @pods << Pod.new(**options)
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
      [98, 99].each {|number| master.add_pod(number: number) }

      staging = Environment.new(name: "Staging")
      [100, 101].each {|number| staging.add_pod(number: number) }

      production = Environment.new(name: "Production")
      (1..6).each {|number| production.add_pod(number: number) }

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
