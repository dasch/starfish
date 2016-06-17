require 'starfish/event_subscriber'

module Starfish
  class DeploySubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def build_released(timestamp, event)
      deploy(event.release)
    end

    def build_automatically_released(timestamp, event)
      deploy(event.release)
    end

    def config_change_released(timestamp, event)
      deploy(event.release)
    end

    private

    def deploy(release)
      $events.record(:release_deployed, {
        release_id: release.id,
      })
    end
  end
end
