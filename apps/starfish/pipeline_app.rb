require 'starfish/flowdock/client'
require 'starfish/service_manifest'
require 'starfish/base_app'

module Starfish
  class PipelineApp < BaseApp
    namespace '/:project/:pipeline' do
      before do
        @project = $repo.find_project_by_slug(params[:project])
        @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
      end

      get '' do
        if @pipeline.channels.any?
          redirect builds_path(@pipeline)
        else
          redirect channels_path(@pipeline)
        end
      end

      get '/settings' do
        erb :show_pipeline_settings
      end

      get '/settings/flowdock' do
        if session[:flowdock_auth].nil?
          redirect "/auth/flowdock"
        end

        @flowdock = Flowdock::Client.new(session[:flowdock_auth].credentials.token)

        @flows = @flowdock.flows

        erb :flowdock_select_flow
      end

      post '/settings/flowdock' do
        if session[:flowdock_auth].nil?
          redirect "/auth/flowdock"
        end

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

      get '/builds' do
        erb :list_builds
      end

      post '/builds/approvals' do
        @build = @pipeline.find_build(number: params[:build_number].to_i)

        $events.record(:build_approved, {
          project_id: @project.id,
          pipeline_id: @pipeline.id,
          build_number: @build.number,
          approved_by: current_user
        })

        redirect builds_path(@pipeline)
      end

      get '/channels' do
        erb :list_channels
      end

      post '/channels' do
        $events.record(:channel_added, {
          id: SecureRandom.uuid,
          name: params[:channel_name],
          auto_release_builds: params[:channel_auto_release] == "1",
          project_id: @project.id,
          pipeline_id: @pipeline.id
        })

        redirect channels_path(@pipeline)
      end

      get '/builds/:build' do
        @build = @pipeline.find_build(number: params[:build].to_i)

        erb :build_layout do
          erb :show_build
        end
      end

      get '/builds/:build/changes' do
        @build = @pipeline.find_build(number: params[:build].to_i)

        erb :build_layout do
          erb :show_build_changes
        end
      end

      get '/builds/:build/commits' do
        @build = @pipeline.find_build(number: params[:build].to_i)

        erb :build_layout do
          erb :show_build_commits
        end
      end

      get '/config' do
        erb :show_pipeline_config
      end

      get '/processes' do
        manifest = ServiceManifest.new(@project, {
          github_token: session[:auth].credentials.token,
          branch: @pipeline.branch
        })

        @processes = manifest.processes

        erb :list_processes
      end
    end
  end
end
