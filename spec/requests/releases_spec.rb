require 'requests/spec_helper'

describe "Releases" do
  before do
    sign_in_with_github
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"
  end

  example "automatically releasing new builds" do
    create_channel(
      project: "skynet",
      pipeline: "production",
      channel_name: "Staging",
      channel_auto_release: "1"
    )

    receive_github_push_event(project: "skynet")

    get "/projects/skynet/production/channels/staging/1"
    expect(last_response.status).to eq 200
  end

  example "manually releasing a build" do
    create_channel(
      project: "skynet",
      pipeline: "production",
      channel_name: "Production",
      channel_auto_release: "0"
    )

    receive_github_push_event(project: "skynet")

    release_build(
      project: "skynet",
      pipeline: "production",
      channel: "production",
      build: "1",
    )

    get "/projects/skynet/production/channels/production/1"
    expect(last_response.status).to eq 200
  end
end
