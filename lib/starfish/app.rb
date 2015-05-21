require 'sinatra/base'

module Starfish
  class Project
    attr_reader :name, :commits, :pipelines

    def initialize(name:)
      @name = name
      @pipelines = []
      @commits = []
    end

    def add_commit(**options)
      commit = Commit.new(**options)
      @commits << commit
      commit
    end

    def add_pipeline(**options)
      pipeline = Pipeline.new(**options.merge(project: self))
      @pipelines << pipeline
      pipeline
    end

    def find_pipeline(slug:)
      @pipelines.find {|b| b.slug == slug }
    end

    def slug
      name.downcase.scan(/\w+/).join("-")
    end

    def to_s
      name
    end
  end

  class Pipeline
    attr_reader :name, :project, :branch, :builds, :channels

    def initialize(name:, branch:, project:)
      @name = name
      @branch = branch
      @project = project
      @builds = []
      @channels = []
    end

    def add_build(**options)
      number = @builds.count + 1
      build = Build.new(**options.merge(pipeline: self, number: number))
      @builds << build
      build
    end

    def find_build(number:)
      @builds.find {|b| b.number == number }
    end

    def add_channel(**options)
      channel = Channel.new(**options.merge(pipeline: self))
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
    attr_reader :pipeline, :name, :releases, :configs

    def initialize(pipeline:, name:)
      @pipeline = pipeline
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
    include Comparable

    attr_reader :number, :commits, :statuses, :image, :pipeline

    def initialize(number:, commits:, image:, pipeline:)
      @number = number
      @image = image
      @commits = commits
      @pipeline = pipeline
      @statuses = []
    end

    def approved?
      true
    end

    def add_status(name:, value:)
      status = Status.new(name: name, value: value)
      @statuses << status
      status
    end

    def status
      if statuses.all?(&:ok?)
        :ok
      elsif statuses.any?(&:pending?)
        :pending
      elsif statuses.any?(&:failed?)
        :failed
      else
        raise "what now?"
      end
    end

    def ok?
      status == :ok
    end

    def failed?
      status == :failed
    end

    def pending?
      status == :pending
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

    def <=>(other)
      number <=> other.number
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
      value == :ok
    end

    def pending?
      value == :pending
    end

    def failed?
      value == :failed
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

  project = $repo.add_project(name: "Zendesk")
  master = project.add_pipeline(name: "Master", branch: "master")
  staging = project.add_pipeline(name: "Staging", branch: "staging")
  production = project.add_pipeline(name: "Production", branch: "production")

  users = [
    User.new(name: "Luke Skywalker"),
    User.new(name: "Darth Vader"),
    User.new(name: "Princess Leia"),
    User.new(name: "Han Solo"),
    User.new(name: "Chewbacca"),
  ]

  [master, staging, production].each do |pipeline|
    30.times do |number|
      commits = (1..5).to_a.sample.times.map {
        project.add_commit(
          sha: SecureRandom.hex,
          author: users.sample,
          additions: (0..100).to_a.sample,
          deletions: (0..100).to_a.sample
        )
      }

      image = ContainerImage.new(id: SecureRandom.hex, namespace: "zendesk", name: "help_center")
      build = pipeline.add_build(commits: commits, image: image)
      build.add_status(name: "Travis CI", value: number > 28 ? :pending : :ok)
      build.add_status(name: "Code Climate", value: :ok)
      build.add_status(name: "System Tests", value: :ok)
    end
  end

  channels = []
  channels << master.add_channel(name: "Master")
  channels << staging.add_channel(name: "Staging")

  %w(Pod1 Pod2 Pod3 Pod4 Pod5 Pod6).each do |channel_name|
    channels << production.add_channel(name: channel_name)
  end

  channels.each do |channel|
    env = {
      "NEW_RELIC_KEY" => "fads834rsd98basaf",
      "MYSQL_URL" => "mysql://fdsafs:fasdfsac@db.zdsys.com/production",
      "REDIS_URL" => "redis://redis1.zdsys.com/0",
    }

    config = channel.add_config(env: env)

    (8..11).to_a.sample.times do |number|
      build = channel.pipeline.find_build(number: (23..29).to_a.sample)
      channel.add_release(build: build, config: config)
    end
  end

  class App < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    helpers do
      def pipeline_nav_items(pipeline)
        items = {
          "Builds" => pipeline_path(pipeline),
          "Channels" => channels_path(pipeline),
          "Releases" => "#",
          "Canaries" => canaries_path(pipeline),
        }

        current_path = items.values.
          select {|path| request.path_info.start_with?(path) }.
          max_by(&:length)

        items.map do |title, path|
          [title, path, path == current_path]
        end
      end

      def build_status(build)
        status = "glyphicon-"
        status << "ok text-success" if build.ok?
        status << "remove text-danger" if build.failed?
        status << "refresh text-info" if build.pending?

        %(<span class="glyphicon #{status}" aria-hidden="true"></span>)
      end

      def project_path(project)
        ["/projects", project.slug].join("/")
      end

      def pipeline_path(pipeline)
        [project_path(pipeline.project), pipeline.slug].join("/")
      end

      def channels_path(pipeline)
        [pipeline_path(pipeline), "channels"].join("/")
      end

      def channel_path(channel)
        [channels_path(channel.pipeline), channel.slug].join("/")
      end

      def canaries_path(pipeline)
        [pipeline_path(pipeline), "canaries"].join("/")
      end

      def release_path(release)
        [channel_path(release.channel), "releases", release.number].join("/")
      end

      def build_path(build)
        [pipeline_path(build.pipeline), "builds", build.number].join("/")
      end
    end

    get '/' do
      @projects = $repo.projects
      erb :list_projects
    end

    get '/projects/:slug/:pipeline' do
      @project = $repo.find_project(slug: params[:slug])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      erb :list_builds
    end

    get '/projects/:project/:pipeline/channels' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      erb :list_channels
    end

    get '/projects/:project/:pipeline/channels/:channel' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      @channel = @pipeline.find_channel(slug: params[:channel])
      erb :show_channel
    end

    get '/projects/:project/:pipeline/channels/:channel/releases/:release' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      @channel = @pipeline.find_channel(slug: params[:channel])
      @release = @channel.find_release(number: params[:release].to_i)
      erb :show_release
    end

    get '/projects/:project/:pipeline/canaries' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      erb :list_canaries
    end
  end
end
