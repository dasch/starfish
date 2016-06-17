require 'starfish/event_subscriber'

module Starfish
  class ReleaseSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def build_automatically_released(timestamp, event)
      build = find_build(event.release)
      release_event = AutomaticReleaseEvent.new(build: build)
      release = add_release(event.release, release_event: release_event, timestamp: timestamp)

      $logger.info "Automatically added release #{release}"
    end

    def build_released(timestamp, event)
      build = find_build(event.release)
      release_event = ManualReleaseEvent.new(build: build)
      release = add_release(event.release, release_event: release_event, timestamp: timestamp)

      $logger.info "Added release #{release}"
    end

    def rollback_released(timestamp, event)
      target_release = find_release(event.release, event.target_release_id)
      release_event = RollbackEvent.new(target_release: target_release)

      release = add_release(event.release, release_event: release_event, timestamp: timestamp)

      $logger.info "Added release #{release} (rolled back to #{target_release})"
    end

    def config_change_released(timestamp, event)
      config_key, config_value = event.config_key, event.config_value
      release_event = ConfigChangedEvent.new(key: config_key, value: config_value)
      release = add_release(event.release, release_event: release_event, timestamp: timestamp)

      $logger.info "Added release #{release} (config key #{config_key} changed)"
    end

    private

    def add_release(event, release_event:, timestamp:)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      build = pipeline.find_build_by_number(event.build_number)
      config = channel.find_config(version: event.config_version)

      author = User.new(
        name: event.author.name,
        username: event.author.username,
        avatar_url: event.author.avatar_url,
      )

      channel.add_release(
        id: event.id,
        build: build,
        config: config,
        author: author,
        event: release_event,
        timestamp: timestamp,
      )
    end

    def find_build(event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)

      pipeline.find_build_by_number(event.build_number)
    end

    def find_release(event, target_release_id)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      channel.find_release(target_release_id)
    end
  end
end
