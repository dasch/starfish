$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require 'bundler/setup'
require 'dotenv'
require 'omniauth'
require 'omniauth/strategies/github'

Dotenv.load

require 'starfish/project_app'
require 'starfish/authentication_app'

require './boot'

use Rack::Session::Cookie

use OmniAuth::Builder do
  client_id = ENV.fetch("GITHUB_CLIENT_ID")
  client_secret = ENV.fetch("GITHUB_CLIENT_SECRET")

  scopes = %w[
    user:email
    repo
    write:repo_hook
  ]

  provider :github, client_id, client_secret, scope: scopes.join(",")
end

map("/auth") { run Starfish::AuthenticationApp }
map("/") { run Starfish::ProjectApp }
