require 'marathon'

module Starfish
  class MarathonSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.data)
      end
    end

    def build_released(data)
      data = data[:release]
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])
      release = channel.find_release(data[:id])

      app_id = "/#{channel.slug}/#{project.slug}-#{pipeline.slug}"
      app_id = project.slug

      configuration = {
        id: app_id,
        cmd: "while true; sleep 10; fi",
        container: {
          type: "DOCKER",
          docker: {
            image: "debian:latest",
            network: "BRIDGE",
          },
        },
      }

      marathon = Marathon.new(ENV.fetch("MARATHON_HOST"))
      $logger.info "Creating Marathon app #{app_id.inspect}..."
      app = marathon.create_app(configuration)
      $logger.info "Created app: #{app}"
    end
  end
end
