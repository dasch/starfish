require 'redis'
require 'snappy'

module Starfish
  class RedisLog
    DEFAULT_KEY = ENV.fetch("STARFISH_EVENTS_KEY", "starfish.events")

    def initialize(key: DEFAULT_KEY, compress: true, redis: Redis.new)
      @key = key
      @redis = redis
      @compress = compress
    end

    def write(data, if_size_equals: nil)
      @redis.watch(@key) unless if_size_equals.nil?

      if if_size_equals != nil && if_size_equals != size
        return nil
      end

      result = @redis.multi {|transaction|
        transaction.rpush(@key, compress(data))
      }

      true
    end

    def events
      @redis.lrange(@key, 0, -1).map {|data| decompress(data) }
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

    private

    def compress(data)
      @compress ? Snappy.deflate(data) : data
    end

    def decompress(data)
      @compress ? Snappy.inflate(data) : data
    end
  end
end
