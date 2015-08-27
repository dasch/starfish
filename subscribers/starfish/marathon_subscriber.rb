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
      deploy(data[:release])
    end

    def build_automatically_released(data)
      deploy(data[:release])
    end

    def config_change_released(data)
      deploy(data[:release])
    end

    private

    def deploy(data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])
      release = channel.find_release(data[:id])

      app_id = "#{project.slug}-#{channel.slug}"

      configuration = {
        args: [],
        instances: 1,
        container: {
          type: "DOCKER",
          docker: {
            image: "docker-registry.zende.sk/starfish",
            forcePullImage: true,
            network: "HOST",
          },
        },
        env: release.config.env,
        force: true,
        constraints: [
          ["hostname", "CLUSTER", "mesos-slave1.pod99.aws1.zdsystest.com"]
        ],
        upgradeStrategy: {
          minimumHealthCapacity: 0
        }
      }

      begin
        marathon = Marathon.new

        $logger.info "Creating Marathon app #{app_id.inspect}..."
        app = marathon.create_or_update_app(app_id, configuration)
        $logger.info "Created app: #{app}"

        $events.record(:release_deployed, {
          release_id: release.id,
        })
      rescue Marathon::Error => e
        $events.record(:release_failed, {
          release_id: release.id,
          error: e.message,
        })

        $logger.error "Release failed: #{e}"
      end
    end
  end
end
