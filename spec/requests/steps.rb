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
    stub_request(:post, "https://api.github.com/repos/luke/deathstar/hooks")
  end

  def receive_github_push_event(project:)
    json = read_fixture("github_push_event.json")

    post "/webhooks/github/skynet", json, {
      "HTTP_X_GITHUB_DELIVERY" => "7aa32c00-0e98-11e5-8696-65a2b4ca4938",
      "HTTP_X_GITHUB_EVENT" => "push",
    }

    expect(last_response.status).to eq 200
  end

  def receive_github_status_event(project:)
    json = read_fixture("github_status_event.json")

    post "/webhooks/github/skynet", json, {
      "HTTP_X_GITHUB_DELIVERY" => "23r9fjfsda-0e98-11e5-8696-65a2b4ca4938",
      "HTTP_X_GITHUB_EVENT" => "status",
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
