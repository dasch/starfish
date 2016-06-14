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
        redirect builds_path(@pipeline)
      end

      get '/builds' do
        erb :list_builds
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
          pipeline_id: @pipeline.id,
          author: current_user,
        })

        redirect channels_path(@pipeline)
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
