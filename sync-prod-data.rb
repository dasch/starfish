require 'redis'

key = "starfish.events.v2"
production_redis = Redis.new(url: ENV["PRODUCTION_REDIS_URL"])
data = production_redis.dump(key)

local_redis = Redis.new
local_redis.del(key)
local_redis.restore(key, 0, data)
