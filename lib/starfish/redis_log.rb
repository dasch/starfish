require 'redis'

module Starfish
  class RedisLog
    DEFAULT_REDIS_KEY = "starfish.events.v2"

    def initialize(key: DEFAULT_REDIS_KEY)
      @key = key
      @redis = Redis.new
    end

    def write(event)
      @redis.rpush(@key, event)
    end

    def events
      @redis.lrange(@key, 0, -1)
    end

    def empty?
      size == 0
    end

    def size
      @redis.llen(@key)
    end

    def clear
      @redis.del(@key)
    end
  end
end
