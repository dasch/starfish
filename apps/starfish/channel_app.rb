require 'starfish/base_app'

module Starfish
  class ChannelApp < BaseApp
    namespace '/:project/:pipeline/channels/:channel' do
      before do
        @project = $repo.find_project_by_slug(params[:project])
        @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
        @channel = @pipeline.find_channel_by_slug(params[:channel])
      end

      get '' do
        redirect releases_path(@channel)
      end

      get '/settings' do
        @channel = @pipeline.find_channel_by_slug(params[:channel])

        erb :channel_layout do
          erb :show_channel_settings
        end
      end

      post '/settings' do
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

      get '/releases' do
        @channel = @pipeline.find_channel_by_slug(params[:channel])

        erb :channel_layout do
          erb :list_releases
        end
      end

      post '/releases' do
        @channel = @pipeline.find_channel_by_slug(params[:channel])

        build = @pipeline.find_build_by_number(params[:build].to_i) or halt(404)
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

      post '/releases/rollbacks' do
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

      get '/config' do
        @channel = @pipeline.find_channel_by_slug(params[:channel])
        @config = @channel.current_config

        erb :channel_layout do
          erb :show_config
        end
      end

      post '/config/keys' do
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

      get '/:release' do
        @channel = @pipeline.find_channel_by_slug(params[:channel])
        @release = @channel.find_release_by_number(params[:release].to_i)
        erb :show_release
      end
    end
  end
end
