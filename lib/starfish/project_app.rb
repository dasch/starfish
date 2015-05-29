require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'
require 'starfish/not_found'

module Starfish
  class ProjectApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    helpers AuthenticationHelpers, UrlHelpers

    error NotFound do
      "Page not found"
    end

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
          "Builds"        => builds_path(pipeline),
          "Channels"      => channels_path(pipeline),
          "Config"        => pipeline_config_path(pipeline),
          "Pull Requests" => pulls_path(pipeline),
          "Canaries"      => canaries_path(pipeline),
        }

        current_path = items.values.
          select {|path| env["REQUEST_PATH"].start_with?(path) }.
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

    get '/:project' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.pipelines.first
      redirect @pipeline ? pipeline_path(@pipeline) : pipelines_path(@project)
    end

    get '/:project/pipelines' do
      @project = $repo.find_project_by_slug(params[:project])
      erb :list_pipelines
    end

    get '/:project/:pipeline' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline]) or halt(404)

      if @pipeline.channels.any?
        redirect builds_path(@pipeline)
      else
        redirect channels_path(@pipeline)
      end
    end

    get '/:project/:pipeline/builds' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :list_builds
    end

    get '/:project/:pipeline/pulls' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :list_pull_requests
    end

    get '/:project/:pipeline/pulls/:pull' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @pull_request = @pipeline.find_pull_request(params[:pull].to_i)
      erb :show_pull_request
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
      redirect releases_path(@channel)
    end

    get '/:project/:pipeline/channels/:channel/settings' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])

      erb :channel_layout do
        erb :show_channel_settings
      end
    end

    post '/:project/:pipeline/channels/:channel/settings' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])

      $events.record(:channel_settings_updated, {
        name: params[:channel_name],
        auto_release_builds: params[:channel_auto_release] == "1",
        project_id: @project.id,
        pipeline_id: @pipeline.id,
        channel_id: @channel.id
      })

      redirect channel_path(@channel)
    end

    get '/:project/:pipeline/channels/:channel/releases' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])

      erb :channel_layout do
        erb :list_releases
      end
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

    post '/:project/:pipeline/channels/:channel/releases/rollbacks' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])

      @release = @channel.find_release(number: params[:release_number].to_i)

      $events.record(:rolled_back_to_release, {
        release_number: @release.number,
        author: current_user,
        project_id: @project.id,
        pipeline_id: @pipeline.id,
        channel_id: @channel.id
      })

      redirect releases_path(@channel)
    end

    get '/:project/:pipeline/channels/:channel/config' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      @config = @channel.current_config

      erb :channel_layout do
        erb :show_config
      end
    end

    post '/:project/:pipeline/channels/:channel/config/keys' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      @config = @channel.current_config

      $events.record(:channel_config_key_added, {
        key: params[:config_key],
        value: params[:config_value],
        config_version: @config.version,
        author: current_user,
        project_id: @project.id,
        pipeline_id: @pipeline.id,
        channel_id: @channel.id
      })

      redirect config_path(@channel)
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

    get '/:project/:pipeline/config' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :show_pipeline_config
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
