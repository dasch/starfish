module Starfish
  class NotificationSubscriber
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
      build = pipeline.find_build(data[:id])

      notify(pipeline, :build_added, build: build)
    end

    def build_automatically_released(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])
      release = channel.find_release(data[:id])

      notify(pipeline, :release_added, release: release)
    end

    private

    def notify(pipeline, event_name, **data)
      pipeline.notification_targets.each do |target|
        target.notify(event_name, **data)
      end
    end
  end
end
