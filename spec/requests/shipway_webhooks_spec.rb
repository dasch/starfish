require 'requests/spec_helper'

describe "Shipway webhooks" do
  before do
    sign_in_with_github
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"
    receive_github_push_event(project: "skynet")
  end

  example "receiving a Shipway build finish event" do
    receive_shipway_build_finish_event(project: "skynet")

    project = $repo.find_project_by_slug("skynet")
    pipeline = project.find_pipeline_by_slug("production")
    build = pipeline.builds.last

    expect(build.docker_builds.count).to eq 1
  end

  def receive_shipway_build_finish_event(project:)
    json = read_fixture("shipway_build_finish_event.json")

    post "/webhooks/shipway/#{project}", json, {
      "HTTP_X_SHIPWAY_EVENT" => "build_finish",
    }

    expect(last_response.status).to eq 200
  end
end
