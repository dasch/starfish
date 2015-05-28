require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'

module Starfish
  class ProjectApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    helpers AuthenticationHelpers, UrlHelpers

    helpers do
      def change_status(status)
        case status
        when :added then '<span class="label label-success">A</span>'
        when :removed then '<span class="label label-danger">R</span>'
        when :modified then '<span class="label label-primary">M</span>'
        end
      end

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
      @project = @projects.first
      redirect @project ? project_path(@project) : setup_path
    end

    get '/:slug' do
      @project = $repo.find_project_by_slug(params[:slug])
      @pipeline = @project.pipelines.first
      redirect @pipeline ? pipeline_path(@pipeline) : pipelines_path(@project)
    end

    get '/:slug/pipelines' do
      @project = $repo.find_project_by_slug(params[:slug])
      erb :list_pipelines
    end

    get '/:slug/:pipeline' do
      @project = $repo.find_project_by_slug(params[:slug])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline]) or halt(404)
      redirect builds_path(@pipeline)
    end

    get '/:slug/:pipeline/builds' do
      @project = $repo.find_project_by_slug(params[:slug])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :list_builds
    end

    get '/:project/:pipeline/channels' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :list_channels
    end

    get '/:project/:pipeline/channels/:channel' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      erb :list_releases
    end

    get '/:project/:pipeline/channels/:channel/releases' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      erb :list_releases
    end

    post '/:project/:pipeline/channels/:channel/releases' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])

      build = @pipeline.find_build(number: params[:build].to_i) or halt(404)
      config = @channel.current_config

      $events.record(:build_released, {
        id: SecureRandom.uuid,
        build_number: build.number,
        config_version: config.version,
        author: current_user,
        project_id: @project.id,
        pipeline_id: @pipeline.id,
        channel_id: @channel.id
      })

      201
    end

    get '/:project/:pipeline/channels/:channel/:release' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      @release = @channel.find_release(number: params[:release].to_i)
      erb :show_release
    end

    get '/:project/:pipeline/builds/:build' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @build = @pipeline.find_build(number: params[:build].to_i)
      erb :show_build
    end

    get '/:project/:pipeline/canaries' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :list_canaries
    end

    post '/:project/pipelines' do
      @project = $repo.find_project_by_slug(params[:project])

      id = SecureRandom.uuid

      $events.record(:pipeline_added, {
        id: id,
        name: params[:pipeline_name],
        branch: params[:pipeline_branch],
        project_id: @project.id
      })

      @pipeline = @project.find_pipeline(id)

      redirect pipeline_path(@pipeline)
    end

    post '/:project/:pipeline/channels' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])

      id = SecureRandom.uuid

      $events.record(:channel_added, {
        id: id,
        name: params[:channel_name],
        auto_release_builds: params[:channel_auto_release] == "1",
        project_id: @project.id,
        pipeline_id: @pipeline.id
      })

      @channel = @pipeline.find_channel(id)

      redirect channel_path(@channel)
    end
  end
end
