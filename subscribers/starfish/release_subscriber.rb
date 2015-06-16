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
      build = find_build(data[:release])
      event = AutomaticReleaseEvent.new(build: build)
      release = add_release(data[:release], event: event)

      $logger.info "Automatically added release #{release}"
    end

    def build_released(timestamp, data)
      build = find_build(data[:release])
      event = ManualReleaseEvent.new(build: build)
      release = add_release(data[:release], event: event)

      $logger.info "Added release #{release}"
    end

    def rollback_released(timestamp, data)
      target_release = find_release(data[:release], data[:target_release_id])
      event = RollbackEvent.new(target_release: target_release)

      release = add_release(data[:release], event: event)

      $logger.info "Added release #{release} (rolled back to #{target_release})"
    end

    def config_change_released(timestamp, data)
      config_key, config_value = data.values_at(:config_key, :config_value)
      event = ConfigChangedEvent.new(key: config_key, value: config_value)
      release = add_release(data[:release], event: event)

      $logger.info "Added release #{release} (config key #{config_key} changed)"
    end

    private

    def add_release(data, event:)
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
        event: event
      )
    end

    def find_build(data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      pipeline.find_build_by_number(data[:build_number])
    end

    def find_release(data, target_release_id)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      channel.find_release(target_release_id)
    end
  end
end
