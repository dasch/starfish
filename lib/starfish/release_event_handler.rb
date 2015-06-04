module Starfish
  class ReleaseEventHandler
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
      build = pipeline.find_build(number: data[:build_number])

      pipeline.channels.each do |channel|
        if channel.auto_release_builds?
          $events.record(:build_automatically_released, {
            id: SecureRandom.uuid,
            build_number: build.number,
            config_version: channel.current_config.version,
            author: build.author,
            project_id: project.id,
            pipeline_id: pipeline.id,
            channel_id: channel.id
          })
        end
      end
    end

    def build_automatically_released(timestamp, data)
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
        event: AutomaticReleaseEvent.new(build: build)
      )

      $stderr.puts "Automatically added release #{release}"
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
  end
end
