require 'requests/spec_helper'

describe "Project Setup" do
  before do
    stub_github_webhook_api
  end

  example "setting up a project" do
    sign_in_with_github

    create_project name: "Skynet", repo: "dasch/dummy"

    expect(last_request.url).to eq "http://example.org/projects/skynet"
  end

  def create_project(name:, repo:)
    post "/setup", name: name, repo: repo
    follow_redirect!
  end

  def stub_github_webhook_api
    stub_request(:post, "https://api.github.com/repos/dasch/dummy/hooks")
  end
end
