require 'redis'

module Starfish
  class NotificationBus
    TIMESTAMP_KEY = "starfish.notification_bus.timestamp"

    def initialize(repo)
      @repo = repo
      @redis = Redis.new
    end

    def notify(pipeline, event_name, timestamp, **data)
      return if stale_notification?(timestamp)

      pipeline.notification_targets.each do |target|
        target.notify(event_name, **data)
      end
    end

    def update_timestamp(timestamp)
      @redis.set(TIMESTAMP_KEY, timestamp.to_i)
    end

    private

    def stale_notification?(timestamp)
      timestamp.to_i <= @redis.get(TIMESTAMP_KEY).to_i
    end
  end
end
