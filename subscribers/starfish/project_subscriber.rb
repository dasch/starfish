require 'starfish/manual_release_event'
require 'starfish/config_changed_event'
require 'starfish/rollback_event'

module Starfish
  class ProjectSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event)
      end
    end

    def project_added(event)
      project = @repo.add_project(
        id: event.aggregate_id,
        name: event.data[:name],
        repo: event.data[:repo]
      )

      $logger.info "Added project #{project}"
    end

    def build_approved(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      build = pipeline.find_build(number: data[:build_number])

      build.approve!(user: data[:approved_by])
    end

    def pipeline_added(event)
      data = event.data
      project = @repo.find_project(event.aggregate_id)

      pipeline = project.add_pipeline(
        id: data.fetch(:pipeline_id),
        name: data.fetch(:name),
        branch: data.fetch(:branch)
      )

      $logger.info "Added pipeline #{pipeline}"
    end

    def channel_added(event)
      data = event.data
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      channel = pipeline.add_channel(
        id: data[:id],
        name: data[:name],
        auto_release_builds: data[:auto_release_builds]
      )

      $logger.info "Added channel #{channel}"
    end

    def channel_settings_updated(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      channel.name = data[:name]
      channel.auto_release_builds = data[:auto_release_builds]
    end

    def channel_config_key_added(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      channel.add_config_key(data[:key], data[:value])

      # We only want to release the config if there's a build we can release it
      # with.
      if channel.releases.any?
        channel.add_release(
          build: channel.current_build,
          config: channel.current_config,
          author: data[:author],
          event: ConfigChangedEvent.new(key: data[:key], value: data[:value])
        )
      end
    end
  end
end
