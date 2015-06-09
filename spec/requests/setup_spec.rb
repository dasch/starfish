require 'requests/spec_helper'

describe "Project Setup" do
  before do
    stub_github_webhook_api
    sign_in_with_github
  end

  example "setting up a project" do
    create_project name: "Skynet", repo: "dasch/dummy"

    expect(last_request.url).to eq "http://example.org/projects/skynet"
  end

  example "adding a pipeline" do
    create_project name: "Skynet", repo: "dasch/dummy"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"
    expect(last_request.url).to eq "http://example.org/projects/skynet/production"
  end

  example "adding a channel" do
    create_project name: "Skynet", repo: "dasch/dummy"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"

    create_channel(
      project: "skynet",
      pipeline: "production",
      channel_name: "Staging",
      channel_auto_release: "1"
    )

    get "/projects/skynet/production/channels/staging/releases"
    expect(last_response.status).to eq 200
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

  def stub_github_webhook_api
    stub_request(:post, "https://api.github.com/repos/dasch/dummy/hooks")
  end
end
