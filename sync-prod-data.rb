require 'redis'

production_redis = Redis.new(url: ENV["PRODUCTION_REDIS_URL"])
data = production_redis.dump("starfish.events")

local_redis = Redis.new
local_redis.del("starfish.events")
local_redis.restore("starfish.events", 0, data)
