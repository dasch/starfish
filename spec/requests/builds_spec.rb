require 'requests/spec_helper'

describe "Builds" do
  before do
    sign_in_with_github
  end

  example "receiving a GitHub push event" do
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"

    receive_github_push_event(project: "skynet")

    get "/projects/skynet/production/builds/1"
    expect(last_response.status).to eq 200
  end
end
