require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'

module Starfish
  class ProjectApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    helpers AuthenticationHelpers, UrlHelpers

    helpers do
      def pipeline_nav_items(pipeline)
        items = {
          "Builds"   => builds_path(pipeline),
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
    end

    before do
      redirect "/auth/signin" if session[:auth].nil?
      @projects = $repo.projects
    end

    get '/' do
      redirect project_path(@projects.first)
    end

    get '/projects/:slug' do
      @project = $repo.find_project(slug: params[:slug])
      erb :list_pipelines
    end

    get '/projects/:slug/:pipeline' do
      @project = $repo.find_project(slug: params[:slug])
      @pipeline = @project.find_pipeline(slug: params[:pipeline]) or halt(404)
      redirect builds_path(@pipeline)
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

    post '/projects/:project/pipelines' do
      @project = $repo.find_project(slug: params[:project])

      @pipeline = @project.add_pipeline(
        name: params[:pipeline_name],
        branch: params[:pipeline_branch]
      )

      $repo.persist!

      redirect pipeline_path(@pipeline)
    end
  end
end
