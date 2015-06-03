require 'redis'

module Starfish
  class NotificationBus
    OFFSET_KEY = "starfish.notification_bus.offset"

    def initialize(repo)
      @repo = repo
      @redis = Redis.new
    end

    def notify(pipeline, event_name, offset, **data)
      return if stale_notification?(offset)

      $stderr.puts "BUS: processing event #{offset}"

      pipeline.notification_targets.each do |target|
        target.notify(event_name, **data)
      end
    end

    def update_offset(offset)
      unless stale_notification?(offset)
        $stderr.puts "BUS: setting high water mark to #{offset}"
        @redis.set(OFFSET_KEY, offset.to_i)
      end
    end

    private

    def stale_notification?(offset)
      offset.to_i <= @redis.get(OFFSET_KEY).to_i
    end
  end
end
