require 'sinatra/base'
require 'starfish/flowdock/client'
require 'starfish/authentication_helpers'
require 'starfish/flash_helpers'
require 'starfish/url_helpers'
require 'starfish/not_found'
require 'starfish/service_manifest'

module Starfish
  class ProjectApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    helpers AuthenticationHelpers, UrlHelpers, FlashHelpers

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
          "Processes"     => processes_path(pipeline),
          "Settings"      => pipeline_settings_path(pipeline),
        }

        current_path = items.values.
          select {|path| env["REQUEST_PATH"].start_with?(path) }.
          max_by(&:length)

        items.map do |title, path|
          [title, path, path == current_path]
        end
      end

      def release_event(release)
        release.author.to_s + " " +
          erb(release.event_name, locals: { event: release.event })
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
      @environments = $repo.environments
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
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])

      if @pipeline.channels.any?
        redirect builds_path(@pipeline)
      else
        redirect channels_path(@pipeline)
      end
    end

    get '/:project/:pipeline/settings' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])

      erb :show_pipeline_settings
    end

    get '/:project/:pipeline/settings/flowdock' do
      if session[:flowdock_auth].nil?
        redirect "/auth/flowdock"
      end

      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @flowdock = Flowdock::Client.new(session[:flowdock_auth].credentials.token)

      @flows = @flowdock.flows

      erb :flowdock_select_flow
    end

    post '/:project/:pipeline/settings/flowdock' do
      if session[:flowdock_auth].nil?
        redirect "/auth/flowdock"
      end

      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @flowdock = Flowdock::Client.new(session[:flowdock_auth].credentials.token)

      params[:flowdock_flows].each do |slug|
        source = @flowdock.add_source(slug, {
          name: "Starfish (#{@project} / #{@pipeline})",
          url: pipeline_path(@pipeline)
        })

        $events.record(:flowdock_source_added, {
          project_id: @project.id,
          pipeline_id: @pipeline.id,
          flowdock_source_id: source.id,
          flowdock_flow_slug: slug,
          flowdock_flow_token: source.flow_token,
          author: current_user
        })
      end

      flash "Flowdock integration added to selected flows"

      redirect pipeline_settings_path(@pipeline)
    end

    get '/:project/:pipeline/builds' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])

      erb :list_builds
    end

    post '/:project/:pipeline/builds/approvals' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @build = @pipeline.find_build(number: params[:build_number].to_i)

      $events.record(:build_approved, {
        project_id: @project.id,
        pipeline_id: @pipeline.id,
        build_number: @build.number,
        approved_by: current_user
      })

      redirect builds_path(@pipeline)
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

      @release = @channel.find_release_by_number(params[:release_number].to_i)

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

      if @config.key?(params[:config_key])
        flash "Config key <code>#{params[:config_key]}</code> is already in use"
      else
        $events.record(:channel_config_key_added, {
          key: params[:config_key],
          value: params[:config_value],
          config_version: @config.version,
          author: current_user,
          project_id: @project.id,
          pipeline_id: @pipeline.id,
          channel_id: @channel.id
        })
      end

      redirect config_path(@channel)
    end

    get '/:project/:pipeline/channels/:channel/:release' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @channel = @pipeline.find_channel_by_slug(params[:channel])
      @release = @channel.find_release_by_number(params[:release].to_i)
      erb :show_release
    end

    get '/:project/:pipeline/builds/:build' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @build = @pipeline.find_build(number: params[:build].to_i)

      erb :build_layout do
        erb :show_build
      end
    end

    get '/:project/:pipeline/builds/:build/changes' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @build = @pipeline.find_build(number: params[:build].to_i)

      erb :build_layout do
        erb :show_build_changes
      end
    end

    get '/:project/:pipeline/builds/:build/commits' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      @build = @pipeline.find_build(number: params[:build].to_i)

      erb :build_layout do
        erb :show_build_commits
      end
    end

    get '/:project/:pipeline/config' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      erb :show_pipeline_config
    end

    get '/:project/:pipeline/processes' do
      @project = $repo.find_project_by_slug(params[:project])
      @pipeline = @project.find_pipeline_by_slug(params[:pipeline])

      manifest = ServiceManifest.new(@project, {
        github_token: session[:auth].credentials.token,
        branch: @pipeline.branch
      })

      @processes = manifest.processes

      erb :list_processes
    end

    post '/:project/pipelines' do
      @project = $repo.find_project_by_slug(params[:project])
      branch = params[:pipeline_branch]

      if @project.has_pipeline_for_branch?(branch)
        pipeline = @project.find_pipeline_by_branch(branch)
        flash "Branch <code>#{branch}</code> has already been assigned to the #{pipeline} pipeline"
        redirect pipelines_path(@project)
      end

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

      $events.record(:channel_added, {
        id: SecureRandom.uuid,
        name: params[:channel_name],
        auto_release_builds: params[:channel_auto_release] == "1",
        project_id: @project.id,
        pipeline_id: @pipeline.id
      })

      redirect channels_path(@pipeline)
    end
  end
end
