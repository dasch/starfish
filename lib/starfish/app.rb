require 'sinatra/base'

module Starfish
  class App < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    helpers do
      def pipeline_nav_items(pipeline)
        items = {
          "Builds" => builds_path(pipeline),
          "Channels" => channels_path(pipeline),
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

      def projects_path
        "/projects"
      end

      def project_path(project)
        ["/projects", project.slug].join("/")
      end

      def pipeline_path(pipeline)
        [project_path(pipeline.project), pipeline.slug].join("/")
      end

      def builds_path(pipeline)
        [pipeline_path(pipeline), "builds"].join("/")
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

      def releases_path(channel)
        [channel_path(channel), "releases"].join("/")
      end

      def release_path(release)
        [channel_path(release.channel), release.number].join("/")
      end

      def build_path(build)
        [pipeline_path(build.pipeline), "builds", build.number].join("/")
      end
    end

    get '/' do
      redirect projects_path
    end

    get '/projects' do
      @projects = $repo.projects
      erb :list_projects, layout: false
    end

    get '/projects/:slug' do
      @project = $repo.find_project(slug: params[:slug])
      erb :list_pipelines
    end

    get '/projects/:slug/:pipeline' do
      @project = $repo.find_project(slug: params[:slug])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      erb :show_pipeline
    end

    get '/projects/:slug/:pipeline/builds' do
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
      erb :list_releases
    end

    get '/projects/:project/:pipeline/channels/:channel/releases' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      @channel = @pipeline.find_channel(slug: params[:channel])
      erb :list_releases
    end

    get '/projects/:project/:pipeline/channels/:channel/releases/:release' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      @channel = @pipeline.find_channel(slug: params[:channel])
      @release = @channel.find_release(number: params[:release].to_i)
      erb :show_release
    end

    get '/projects/:project/:pipeline/builds/:build' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      @build = @pipeline.find_build(number: params[:build].to_i)
      erb :show_build
    end

    get '/projects/:project/:pipeline/canaries' do
      @project = $repo.find_project(slug: params[:project])
      @pipeline = @project.find_pipeline(slug: params[:pipeline])
      erb :list_canaries
    end
  end
end
