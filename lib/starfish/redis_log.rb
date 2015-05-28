require 'redis'

module Starfish
  class RedisLog
    DEFAULT_REDIS_KEY = "starfish.events"

    def initialize(key: DEFAULT_REDIS_KEY)
      @key = key
      @redis = Redis.new
    end

    def write(event)
      @redis.rpush(@key, Marshal.dump(event))
    end

    def events
      @redis.lrange(@key, 0, -1).map {|data| Marshal.load(data) }
    end

    def empty?
      @redis.llen(@key) == 0
    end

    def clear
      @redis.del(@key)
    end
  end
end
