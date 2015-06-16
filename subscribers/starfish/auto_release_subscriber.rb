module Starfish
  class AutoReleaseSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def build_pushed(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      build = pipeline.find_build(data.fetch(:id))

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

    def channel_config_key_added(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      # We only want to release the config if there's a build we can release it
      # with.
      if channel.releases.any?
        $events.record(:config_change_released, {
          config_key: data[:key],
          config_value: data[:value],
          release: {
            id: SecureRandom.uuid,
            build_number: channel.current_build.number,
            config_version: channel.current_config.version,
            author: data[:author],
            project_id: project.id,
            pipeline_id: pipeline.id,
            channel_id: channel.id
          }
        })
      end
    end
  end
end