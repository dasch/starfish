require 'sinatra/base'

module Starfish
  class Project
    attr_reader :name, :commits, :branches, :channels

    def initialize(name:)
      @name = name
      @commits = []
      @branches = []
      @channels = []
    end

    def add_commit(**options)
      commit = Commit.new(**options)
      @commits << commit
      commit
    end

    def add_branch(**options)
      branch = Branch.new(**options.merge(project: self))
      @branches << branch
      branch
    end

    def find_branch(name:)
      @branches.find {|b| b.name == name }
    end

    def master_branch
      find_branch(name: "master")
    end

    def add_channel(**options)
      channel = Channel.new(**options.merge(project: self))
      @channels << channel
      channel
    end

    def find_channel(slug:)
      @channels.find {|c| c.slug == slug }
    end

    def releases_for_build(build)
      @channels.find_all {|c| c.current_build == build }.map(&:current_release)
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end

  class Channel
    attr_reader :project, :name, :releases, :configs

    def initialize(project:, name:)
      @project = project
      @name = name
      @releases = []
      @configs = []
    end

    def current_release
      releases.last
    end

    def current_build
      current_release.build
    end

    def add_release(**options)
      number = @releases.count + 1
      release = Release.new(**options.merge(channel: self, number: number))
      @releases << release
      release
    end

    def find_release(number:)
      @releases.find {|b| b.number == number }
    end

    def add_config(**options)
      config = Config.new(**options)
      @configs << config
      config
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end

  class Release
    attr_reader :build, :config, :number, :channel

    def initialize(build:, config:, number:, channel:)
      @build, @config, @number, @channel = build, config, number, channel
    end

    def authors
      build.authors
    end

    def to_s
      "v#{number}"
    end
  end

  class Build
    attr_reader :number, :commits, :statuses, :image, :branch

    def initialize(number:, commits:, image:, branch:)
      @number, @project, @image = number, project, image
      @commits = commits
      @branch = branch
      @statuses = []
    end

    def project
      @branch && @branch.project
    end

    def add_status(name:, value:)
      status = Status.new(name: name, value: value)
      @statuses << status
      status
    end

    def ok?
      statuses.all?(&:ok?)
    end

    def commit
      commits.last
    end

    def authors
      commits.flat_map(&:author).uniq
    end

    def additions
      commits.map(&:additions).inject(0, &:+)
    end

    def deletions
      commits.map(&:deletions).inject(0, &:+)
    end

    def ==(other)
      branch == other.branch && commit == other.commit
    end

    def to_s
      "##{number}"
    end
  end

  class Commit
    attr_reader :sha, :author, :additions, :deletions

    def initialize(sha:, author:, additions:, deletions:)
      @sha = sha
      @author = author
      @additions = additions
      @deletions = deletions
    end

    def to_s
      sha
    end
  end

  class Branch
    attr_reader :name, :project, :builds

    def initialize(name:, project:)
      @name, @project = name, project
      @builds = []
    end

    def add_build(**options)
      number = @builds.count + 1
      build = Build.new(**options.merge(branch: self, number: number))
      @builds << build
      build
    end

    def find_build(number:)
      @builds.find {|b| b.number == number }
    end

    def to_s
      name
    end
  end

  class Config
    attr_reader :env

    def initialize(env:)
      @env = env
    end
  end

  class Status
    attr_reader :name, :value

    def initialize(name:, value:)
      @name, @value = name, value
    end

    def ok?
      value != "Failed"
    end
  end

  class ContainerImage
    attr_reader :id, :namespace, :name

    def initialize(id:, namespace:, name:)
      @id, @namespace, @name = id, namespace, name
    end

    def to_s
      "#{namespace}/#{name}:#{id}"
    end
  end

  class User
    attr_reader :name

    def initialize(name:)
      @name = name
    end

    def ==(other)
      name == other.name
    end

    def to_s
      name
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

  project = $repo.add_project(name: "Help Center")
  branch = project.add_branch(name: "master")

  users = [
    User.new(name: "Luke Skywalker"),
    User.new(name: "Darth Vader"),
    User.new(name: "Princess Leia"),
    User.new(name: "Han Solo"),
    User.new(name: "Chewbacca"),
  ]

  30.times do
    commits = (1..5).to_a.sample.times.map {
      project.add_commit(
        sha: SecureRandom.hex,
        author: users.sample,
        additions: (0..100).to_a.sample,
        deletions: (0..100).to_a.sample
      )
    }

    image = ContainerImage.new(id: SecureRandom.hex, namespace: "zendesk", name: "help_center")
    build = branch.add_build(commits: commits, image: image)
    build.add_status(name: "Travis CI", value: "Pending")
    build.add_status(name: "Code Climate", value: "Passed")
    build.add_status(name: "System Tests", value: "Passed")
  end

  %w(Staging Pod1 Pod2 Pod3 Pod4 Pod5 Pod6).each do |channel_name|
    channel = project.add_channel(name: channel_name)

    env = {
      "NEW_RELIC_KEY" => "fads834rsd98basaf",
      "MYSQL_URL" => "mysql://fdsafs:fasdfsac@db.zdsys.com/production",
      "REDIS_URL" => "redis://redis1.zdsys.com/0",
    }

    config = channel.add_config(env: env)

    (8..11).to_a.sample.times do |number|
      build = branch.find_build(number: (23..29).to_a.sample)
      channel.add_release(build: build, config: config)
    end
  end

  class App < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    helpers do
      def build_status(build)
        icon = build.ok? ? "glyphicon-ok" : "glyphicon-remove"
        %(<span class="glyphicon #{icon}" aria-hidden="true"></span>)
      end

      def project_path(project)
        ["/projects", project.slug].join("/")
      end

      def channel_path(channel)
        [project_path(channel.project), "channels", channel.slug].join("/")
      end

      def release_path(release)
        [channel_path(release.channel), "releases", release.number].join("/")
      end

      def branch_path(branch)
        [project_path(branch.project), "branches", branch.name].join("/")
      end

      def build_path(build)
        [branch_path(build.branch), "builds", build.number].join("/")
      end

      def branch_path(branch)
        [project_path(branch.project), "branches", branch.name].join("/")
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

    get '/projects/:project/channels/:channel' do
      @project = $repo.find_project(slug: params[:project])
      @channel = @project.find_channel(slug: params[:channel])
      erb :show_channel
    end

    get '/projects/:project/channels/:channel/releases/:release' do
      @project = $repo.find_project(slug: params[:project])
      @channel = @project.find_channel(slug: params[:channel])
      @release = @channel.find_release(number: params[:release].to_i)
      erb :show_release
    end

    get '/projects/:project/branches/:branch' do
      @project = $repo.find_project(slug: params[:project])
      @branch = @project.find_branch(name: params[:branch])
      erb :show_branch
    end

    get '/projects/:project/branches/:branch/builds/:build' do
      @project = $repo.find_project(slug: params[:project])
      @branch = @project.find_branch(name: params[:branch])
      @build = @branch.find_build(number: params[:build].to_i)
      erb :show_build
    end
  end
end
