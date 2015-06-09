require 'requests/spec_helper'

describe "Project Setup" do
  before do
    sign_in_with_github
  end

  example "setting up a project" do
    create_project name: "Skynet", repo: "luke/deathstar"

    expect(last_request.url).to eq "http://example.org/projects/skynet"
  end

  example "adding a pipeline" do
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"
    expect(last_request.url).to eq "http://example.org/projects/skynet/production"
  end

  example "adding a channel" do
    create_project name: "Skynet", repo: "luke/deathstar"
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
end
