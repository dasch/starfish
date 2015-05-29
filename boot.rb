require 'starfish/repository'
require 'starfish/user'
require 'starfish/container_image'
require 'starfish/event_store'
require 'starfish/redis_log'
require 'starfish/project_event_handler'
require 'starfish/github_event_handler'

$stderr.puts "=== Booting ==="

$repo = Starfish::Repository.new

$events = Starfish::EventStore.new(log: Starfish::RedisLog.new)
$events.add_observer(Starfish::ProjectEventHandler.new($repo))
$events.add_observer(Starfish::GithubEventHandler.new($repo))
$events.replay!
