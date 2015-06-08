require 'redis'
require 'snappy'

module Starfish
  class RedisLog
    DEFAULT_REDIS_KEY = "starfish.events.v3"

    def initialize(key: DEFAULT_REDIS_KEY, compress: true)
      @key = key
      @redis = Redis.new
      @compress = compress
    end

    def write(data)
      @redis.rpush(@key, compress(data))
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
