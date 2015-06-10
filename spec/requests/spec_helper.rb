ENV["RACK_ENV"] = "test"

require 'bundler/setup'
require 'byebug'
require 'omniauth'
require 'rack/test'
require 'webmock/rspec'

require_relative 'steps'

OmniAuth.config.test_mode = true

APP_UNDER_TEST = Rack::Builder.parse_file('config.ru').first

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

  def read_fixture(filename)
    File.read(File.join("spec", "fixtures", filename))
  end
end
