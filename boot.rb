require 'starfish/repository'
require 'starfish/user'
require 'starfish/container_image'
require 'starfish/event_store'
require 'starfish/event_handler'
require 'starfish/redis_log'

$stderr.puts "=== Booting ==="

$repo = Starfish::Repository.new

$events = Starfish::EventStore.new(log: Starfish::RedisLog.new)
$events.add_observer(Starfish::EventHandler.new($repo))
$events.replay!
