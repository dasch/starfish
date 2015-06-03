require 'starfish/flowdock/notification_target'

module Starfish
  class FlowdockEventHandler
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def flowdock_source_added(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      target = Flowdock::NotificationTarget.new(
        slug: data[:flowdock_flow_slug],
        source_id: data[:flowdock_source_id],
        flow_token: data[:flowdock_flow_token]
      )

      pipeline.add_notification_target(target)
    end
  end
end
