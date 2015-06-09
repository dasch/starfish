ENV["RACK_ENV"] = "test"
ENV["STARFISH_EVENTS_KEY"] = "starfish.test.events"

require 'bundler/setup'
require 'byebug'
require 'omniauth'
require 'rack/test'
require 'webmock/rspec'

OmniAuth.config.test_mode = true

APP_UNDER_TEST = Rack::Builder.parse_file('config.ru').first

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.after do
    $events.clear
    $repo.clear
  end

  def app
    APP_UNDER_TEST
  end

  def sign_in_with_github
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: 'github',
      uid: '123545',
      info: {
        name: 'Average Joe',
        nickname: 'joe',
      },
      credentials: {
        token: SecureRandom.hex,
        secret: SecureRandom.hex,
      }
    })

    get '/auth/github/callback'
    follow_redirect!
  end
end
