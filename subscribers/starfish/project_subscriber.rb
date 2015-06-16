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
        send(event.name, event.timestamp, event.data)
      end
    end

    def project_added(timestamp, data)
      project = @repo.add_project(
        id: data[:id],
        name: data[:name],
        repo: data[:repo]
      )

      $logger.info "Added project #{project}"
    end

    def build_approved(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      build = pipeline.find_build_by_number(data[:build_number])

      build.approve!(user: data[:approved_by])
    end

    def pipeline_added(timestamp, data)
      project = @repo.find_project(data[:project_id])

      pipeline = project.add_pipeline(
        id: data[:id],
        name: data[:name],
        branch: data[:branch]
      )

      $logger.info "Added pipeline #{pipeline}"
    end

    def channel_added(timestamp, data)
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
    end
  end
end
