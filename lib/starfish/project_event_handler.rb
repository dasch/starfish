require 'starfish/manual_release_event'
require 'starfish/config_changed_event'
require 'starfish/rollback_event'

module Starfish
  class ProjectEventHandler
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

      $stderr.puts "Added project #{project}"
    end

    def build_released(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      build = pipeline.find_build(number: data[:build_number])
      config = channel.find_config(version: data[:config_version])
      author = data[:author]

      release = channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author,
        event: ManualReleaseEvent.new(build: build)
      )

      $stderr.puts "Added release #{release}"
    end

    def build_approved(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      build = pipeline.find_build(number: data[:build_number])

      build.approve!(user: data[:approved_by])
    end

    def rolled_back_to_release(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      target_release = channel.find_release(number: data[:release_number])
      author = data[:author]

      release = channel.add_release(
        build: target_release.build,
        config: target_release.config,
        author: author,
        event: RollbackEvent.new(target_release: target_release)
      )

      $stderr.puts "Added release #{release}"
    end

    def pipeline_added(timestamp, data)
      project = @repo.find_project(data[:project_id])

      pipeline = project.add_pipeline(
        id: data[:id],
        name: data[:name],
        branch: data[:branch]
      )

      $stderr.puts "Added pipeline #{pipeline}"
    end

    def channel_added(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      channel = pipeline.add_channel(
        id: data[:id],
        name: data[:name],
        auto_release_builds: data[:auto_release_builds]
      )

      $stderr.puts "Added channel #{channel}"
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
