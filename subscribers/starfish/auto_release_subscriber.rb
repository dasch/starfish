require 'starfish/event_subscriber'

module Starfish
  class AutoReleaseSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def build_pushed(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      build = pipeline.find_build(event.id)

      pipeline.channels.each do |channel|
        if channel.auto_release_builds?
          $events.record(:build_automatically_released, {
            release: {
              id: SecureRandom.uuid,
              build_number: build.number,
              config_version: channel.current_config.version,
              author: build.author,
              project_id: project.id,
              pipeline_id: pipeline.id,
              channel_id: channel.id
            }
          })
        end
      end
    end

    def channel_config_value_changed(timestamp, event)
      channel_config_key_added(timestamp, event)
    end

    def channel_config_key_added(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      # We only want to release the config if there's a build we can release it
      # with.
      if channel.releases.any?
        $events.record(:config_change_released, {
          config_key: event.key,
          config_value: event.value,
          release: {
            id: SecureRandom.uuid,
            build_number: channel.current_build.number,
            config_version: channel.current_config.version,
            author: event.author,
            project_id: project.id,
            pipeline_id: pipeline.id,
            channel_id: channel.id
          }
        })
      end
    end
  end
end
