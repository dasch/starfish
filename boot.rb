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

master = $repo.add_environment(name: "master-eu1")
staging = $repo.add_environment(name: "staging-eu1")
prod1 = $repo.add_environment(name: "prod-eu1")
prod2 = $repo.add_environment(name: "prod-us1")
prod3 = $repo.add_environment(name: "prod-us2")

$repo.projects.each do |project|
  project.pipelines.each do |pipeline|
    pipeline.channels.each do |channel|
      environment = case channel.name.downcase
      when /master/ then master
      when /staging/ then staging
      when /pod/, /production/ then [prod1, prod2, prod3].sample
      end

      channel.environment = environment
      environment.channels << channel
    end
  end
end

$events.add_observer(Starfish::AutoReleaseSubscriber.new($repo))
$events.add_observer(Starfish::NotificationSubscriber.new($repo))
$events.add_observer(Starfish::DeploySubscriber.new($repo))
