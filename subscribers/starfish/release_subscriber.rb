module Starfish
  class ReleaseSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def build_automatically_released(timestamp, data)
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      build = pipeline.find_build_by_number(data[:build_number])
      config = channel.find_config(version: data[:config_version])

      author = User.new(
        name: data[:author][:name],
        username: data[:author][:username],
        avatar_url: data[:author][:avatar_url],
      )

      release = channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author,
        event: AutomaticReleaseEvent.new(build: build)
      )

      $logger.info "Automatically added release #{release}"
    end

    def build_released(timestamp, data)
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      build = pipeline.find_build_by_number(data[:build_number])
      config = channel.find_config(version: data[:config_version])

      author = User.new(
        name: data[:author][:name],
        username: data[:author][:username],
        avatar_url: data[:author][:avatar_url],
      )

      release = channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author,
        event: ManualReleaseEvent.new(build: build)
      )

      $logger.info "Added release #{release}"
    end

    def rollback_released(timestamp, data)
      target_release_id = data[:target_release_id]
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      target_release = channel.find_release(target_release_id)
      build = pipeline.find_build_by_number(data[:build_number])
      config = channel.find_config(version: data[:config_version])

      author = User.new(
        name: data[:author][:name],
        username: data[:author][:username],
        avatar_url: data[:author][:avatar_url],
      )

      release = channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author,
        event: RollbackEvent.new(target_release: target_release)
      )

      $logger.info "Added release #{release}"
    end

    def config_change_released(timestamp, data)
      config_key, config_value = data.values_at(:config_key, :config_value)
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      build = pipeline.find_build_by_number(data[:build_number])
      config = channel.find_config(version: data[:config_version])

      author = User.new(
        name: data[:author][:name],
        username: data[:author][:username],
        avatar_url: data[:author][:avatar_url],
      )

      channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author,
        event: ConfigChangedEvent.new(key: config_key, value: config_value)
      )
    end
  end
end
