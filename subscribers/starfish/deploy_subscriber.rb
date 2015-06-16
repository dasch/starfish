module Starfish
  class DeploySubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def build_released(timestamp, data)
      deploy(data[:release])
    end

    def build_automatically_released(timestamp, data)
      deploy(data[:release])
    end

    def config_change_released(timestamp, data)
      deploy(data[:release])
    end

    private

    def deploy(release)
      $events.record(:release_deployed, {
        release_id: release[:id],
      })
    end
  end
end
