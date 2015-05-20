require 'sinatra/base'

module Starfish
  class Project
    attr_reader :name, :releases, :builds

    def initialize(name:, releases: [], builds: [])
      @name = name
      @releases = releases
      @builds = builds
    end

    def add_release(number:)
      @releases << Release.new(number: number, project: self)
    end

    def find_release(number:)
      @releases.find {|b| b.number == number }
    end

    def add_build(number:)
      @builds << Build.new(number: number, project: self)
    end

    def find_build(number:)
      @builds.find {|b| b.number == number }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end

  class Release
    attr_reader :number, :project

    def initialize(number:, project:)
      @number, @project = number, project
    end

    def to_s
      "v#{number}"
    end
  end

  class Build
    attr_reader :number, :project

    def initialize(number:, project:)
      @number, @project = number, project
    end

    def to_s
      "##{number}"
    end
  end

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

  $repo = Repository.new
  $repo.add_project(name: "Voice")

  project = $repo.add_project(name: "Help Center")

  1.upto(11).each do |number|
    project.add_release(number: number)
  end

  1.upto(32).each do |number|
    project.add_build(number: number)
  end

  class App < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    helpers do
      def project_path(project)
        ["/projects", project.slug].join("/")
      end

      def release_path(release)
        [project_path(release.project), "releases", release.number].join("/")
      end

      def build_path(build)
        [project_path(build.project), "builds", build.number].join("/")
      end
    end

    get '/' do
      @projects = $repo.projects
      erb :list_projects
    end

    get '/projects/:slug' do
      @project = $repo.find_project(slug: params[:slug])
      erb :show_project
    end

    get '/projects/:slug/releases/:number' do
      @project = $repo.find_project(slug: params[:slug])
      @release = @project.find_release(number: params[:number].to_i)
      erb :show_release
    end

    get '/projects/:slug/builds/:number' do
      @project = $repo.find_project(slug: params[:slug])
      @build = @project.find_build(number: params[:number].to_i)
      erb :show_build
    end
  end
end
