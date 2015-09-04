require 'starfish/repository'
require 'starfish/event_store'
require 'starfish/redis_log'
require 'starfish/project_subscriber'
require 'starfish/build_subscriber'
require 'starfish/github_subscriber'
require 'starfish/shipway_webhook_subscriber'
require 'starfish/flowdock_subscriber'
require 'starfish/notification_subscriber'
require 'starfish/release_subscriber'
require 'starfish/auto_release_subscriber'
require 'starfish/deploy_subscriber'
require 'starfish/image_build_subscriber'

$logger.info "=== Booting ==="

$repo = Starfish::Repository.new

$events = Starfish::EventStore.new(log: Starfish::RedisLog.new)
$events.add_observer(Starfish::ProjectSubscriber.new($repo))
$events.add_observer(Starfish::BuildSubscriber.new($repo))
$events.add_observer(Starfish::GithubSubscriber.new($repo))
$events.add_observer(Starfish::ReleaseSubscriber.new($repo))
$events.add_observer(Starfish::FlowdockSubscriber.new($repo))
$events.add_observer(Starfish::ShipwayWebhookSubscriber.new($repo))

$events.replay!

$events.add_observer(Starfish::AutoReleaseSubscriber.new($repo))
$events.add_observer(Starfish::NotificationSubscriber.new($repo))
$events.add_observer(Starfish::ImageBuildSubscriber.new($repo))
$events.add_observer(Starfish::DeploySubscriber.new($repo))
