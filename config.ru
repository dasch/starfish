$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require 'bundler/setup'
require 'dotenv'
require 'omniauth'
require 'omniauth/strategies/github'
require 'omniauth/strategies/flowdock'

Dotenv.load

require 'starfish/setup_app'
require 'starfish/project_app'
require 'starfish/authentication_app'
require 'starfish/webhook_app'

if ENV["RACK_ENV"] == "development"
  require 'byebug'

  if ENV["PROFILE"] == "true"
    require 'rack-mini-profiler'
    use Rack::MiniProfiler
  end
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

  flowdock_client_id = ENV.fetch("FLOWDOCK_CLIENT_ID")
  flowdock_client_secret = ENV.fetch("FLOWDOCK_CLIENT_SECRET")

  provider :github, github_client_id, github_client_secret, scope: github_scopes.join(",")
  provider :flowdock, flowdock_client_id, flowdock_client_secret, scope: "flow integration"
end

map("/setup") { run Starfish::SetupApp }
map("/auth") { run Starfish::AuthenticationApp }
map("/webhooks") { run Starfish::WebhookApp }
map("/projects") { run Starfish::ProjectApp }
map("/") { run ->(env) { [301, { "Location" => "/projects" }, []] } }
