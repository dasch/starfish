$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
$LOAD_PATH.unshift(File.expand_path("../apps", __FILE__))
$LOAD_PATH.unshift(File.expand_path("../subscribers", __FILE__))

require 'bundler/setup'
require 'dotenv'
require 'omniauth'
require 'omniauth/strategies/github'
require 'avromatic'

Dotenv.load unless ENV["RACK_ENV"] == "production"
Dotenv.load(".env.test") if ENV["RACK_ENV"] == "test"

require 'starfish/setup_app'
require 'starfish/project_app'
require 'starfish/authentication_app'
require 'starfish/github_webhook_app'
require 'starfish/shipway_webhook_app'

if ENV["RACK_ENV"] == "development"
  require 'byebug'

  if ENV["PROFILE"] == "true"
    require 'rack-mini-profiler'
    use Rack::MiniProfiler
  end
end

$logger = Logger.new(ENV["LOG_FILE"] || $stderr)

Avromatic.configure do |config|
  config.schema_store = AvroTurf::SchemaStore.new(path: 'schemas/')
end

require './boot'

use Rack::Session::Cookie, secret: ENV.fetch("SESSION_SECRET")

use OmniAuth::Builder do
  github_client_id = ENV.fetch("GITHUB_CLIENT_ID")
  github_client_secret = ENV.fetch("GITHUB_CLIENT_SECRET")

  github_scopes = %w[
    user:email
    repo
    write:repo_hook
  ]

  provider :github, github_client_id, github_client_secret, scope: github_scopes.join(",")
end

map("/setup") { run Starfish::SetupApp }
map("/auth") { run Starfish::AuthenticationApp }
map("/webhooks/github") { run Starfish::GithubWebhookApp }
map("/webhooks/shipway") { run Starfish::ShipwayWebhookApp }

map("/projects") do
  run Rack::Cascade.new([
    Starfish::ProjectApp,
    Starfish::PipelineApp,
    Starfish::BuildApp,
    Starfish::ChannelApp
  ])
end

map("/") { run ->(env) { [301, { "Location" => "/projects" }, []] } }
