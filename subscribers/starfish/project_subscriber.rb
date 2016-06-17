require 'starfish/event_subscriber'
require 'starfish/manual_release_event'
require 'starfish/config_changed_event'
require 'starfish/rollback_event'

module Starfish
  class ProjectSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def project_added(timestamp, event)
      project = @repo.add_project(
        id: event.id,
        name: event.name,
        repo: event.repo
      )

      $logger.info "Added project #{project}"
    end

    def project_renamed(timestamp, event)
      project = @repo.find_project(event.id)
      project.rename(event.name)

      $logger.info "Renamed project #{project.id} to #{project.name}"
    end

    def pipeline_added(timestamp, event)
      project = @repo.find_project(event.project_id)

      pipeline = project.add_pipeline(
        id: event.id,
        name: event.name,
        branch: event.branch
      )

      $logger.info "Added pipeline #{pipeline}"
    end

    def pipeline_removed(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)

      project.remove_pipeline(pipeline.id)

      $logger.info "Removed pipeline #{pipeline}"
    end

    def channel_added(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)

      channel = pipeline.add_channel(
        id: event.id,
        name: event.name,
        auto_release_builds: event.auto_release_builds
      )

      $logger.info "Added channel #{channel}"
    end

    def channel_settings_updated(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      channel.name = event.name
      channel.auto_release_builds = event.auto_release_builds
    end

    def channel_config_key_added(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      channel.add_config_key(event.key, event.value)
    end

    def channel_config_value_changed(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)
      channel = pipeline.find_channel(event.channel_id)

      channel.change_config_value(event.key, event.value)
    end
  end
end
