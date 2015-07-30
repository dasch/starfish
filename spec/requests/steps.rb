require 'sinatra/base'
require 'sinatra/json'

module Steps
  class FakeGitHubApi
    attr_reader :secret

    def call(env)
      params = JSON.parse(env["rack.input"].read)

      @secret = params.fetch("config").fetch("secret")

      headers = { "Content-Type" => "application/json" }
      body = { "id" => 42 }

      [200, headers, [body.to_json]]
    end
  end

  def fake_github
    @fake_github ||= FakeGitHubApi.new
  end

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

  def release_build(project:, pipeline:, channel:, **params)
    post "/projects/#{project}/#{pipeline}/channels/#{channel}/releases", params
    expect(last_response.status).to eq 201
  end

  def stub_github_webhook_api
    stub_request(:post, "https://api.github.com/repos/luke/deathstar/hooks").
      to_rack(fake_github)
  end

  def stub_marathon_api
    base = ENV.fetch("MARATHON_URL")

    stub_request(:get, %r"#{base}/v2/apps/.+")
    stub_request(:put, %r"#{base}/v2/apps/.+").to_return(body: JSON.dump({}))
    stub_request(:post, "#{base}/v2/apps").to_return(status: 201, body: "null") 
  end

  def receive_github_push_event(**options)
    json = read_fixture("github_push_event.json")
    receive_github_event(json: json, type: "push", **options)
  end

  def receive_github_pull_request_opened_event(**options)
    json = read_fixture("github_pull_request_opened_event.json")
    receive_github_event(json: json, type: "pull_request", **options)
  end

  def receive_github_status_event(**options)
    json = read_fixture("github_status_event.json")
    receive_github_event(json: json, type: "status", **options)
  end

  def receive_github_event(project:, type:, json:, event_id: SecureRandom.uuid)
    secret = fake_github.secret
    digest = OpenSSL::Digest.new('sha1')
    signature = 'sha1=' << OpenSSL::HMAC.hexdigest(digest, secret, json)

    post "/webhooks/github/#{project}", json, {
      "HTTP_X_GITHUB_DELIVERY" => event_id,
      "HTTP_X_GITHUB_EVENT" => type,
      "HTTP_X_HUB_SIGNATURE" => signature,
    }

    expect(last_response.status).to eq 200
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
