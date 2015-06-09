ENV["RACK_ENV"] = "test"
ENV["STARFISH_EVENTS_KEY"] = "starfish.test.events"

require 'bundler/setup'
require 'byebug'
require 'omniauth'
require 'rack/test'
require 'webmock/rspec'

OmniAuth.config.test_mode = true

APP_UNDER_TEST = Rack::Builder.parse_file('config.ru').first

module Steps
  def create_project(**params)
    post "/setup", params
    follow_redirect!
  end

  def create_pipeline(project:, **params)
    post "/projects/#{project}/pipelines", params
    follow_redirect!
  end

  def create_channel(project:, pipeline:, **params)
    post "/projects/#{project}/#{pipeline}/channels", params
    follow_redirect!
  end

  def stub_github_webhook_api
    stub_request(:post, "https://api.github.com/repos/dasch/dummy/hooks")
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Steps

  config.before do
    stub_github_webhook_api
  end

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
