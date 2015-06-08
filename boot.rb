require 'starfish/repository'
require 'starfish/event_store'
require 'starfish/redis_log'
require 'starfish/project_subscriber'
require 'starfish/github_subscriber'
require 'starfish/shipway_webhook_subscriber'
require 'starfish/flowdock_subscriber'
require 'starfish/notification_subscriber'
require 'starfish/release_subscriber'

require 'starfish/avro_event_serializer'

$stderr.puts "=== Booting ==="

class MigrationSubscriber
  def initialize(events)
    @events = events
  end

  def update(event)
    puts "--> Migrating event #{event.name}"
    @events.record(event.name, event.data, timestamp: event.timestamp)
  end
end

$repo = Starfish::Repository.new

log = Starfish::RedisLog.new(key: "starfish.events.v4")
log.clear

$events = Starfish::EventStore.new(
  log: log,
  serializer: Starfish::AvroEventSerializer.new
)

legacy_events = Starfish::EventStore.new(
  log: Starfish::RedisLog.new,
  serializer: Starfish::MarshalEventSerializer.new
)

legacy_events.add_observer(MigrationSubscriber.new($events))
legacy_events.replay!

$events.add_observer(Starfish::ProjectSubscriber.new($repo))
$events.add_observer(Starfish::GithubSubscriber.new($repo))
$events.add_observer(Starfish::ReleaseSubscriber.new($repo))
$events.add_observer(Starfish::FlowdockSubscriber.new($repo))
$events.add_observer(Starfish::ShipwayWebhookSubscriber.new($repo))

$events.replay!

$events.add_observer(Starfish::NotificationSubscriber.new($repo))
