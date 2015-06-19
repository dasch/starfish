require 'requests/spec_helper'

describe "GitHub webhooks" do
  before do
    sign_in_with_github
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"
  end

  example "receiving a GitHub push event" do
    receive_github_push_event(project: "skynet")

    get "/projects/skynet/production/builds/1"
    expect(last_response.status).to eq 200
  end

  example "receiving a GitHub status event" do
    receive_github_push_event(project: "skynet")
    receive_github_status_event(project: "skynet")

    project = $repo.find_project_by_slug("skynet")
    pipeline = project.find_pipeline_by_slug("production")
    build = pipeline.find_build_by_number(1)

    expect(build.status).to be_ok
  end

  example "receiving a GitHub pull request opened event" do
    receive_github_push_event(project: "skynet")
    receive_github_status_event(project: "skynet")
    receive_github_pull_request_opened_event(project: "skynet")

    project = $repo.find_project_by_slug("skynet")
    pipeline = project.find_pipeline_by_slug("production")

    expect(pipeline.pull_requests.last.title).to eq "Improve ventilation"
  end

  example "receiving a duplicate GitHub event" do
    event_id = "7aa32c00-0e98-11e5-8696-65a2b4ca4938"

    receive_github_push_event(project: "skynet", event_id: event_id)
    receive_github_push_event(project: "skynet", event_id: event_id)

    get "/projects/skynet/production/builds/1"
    expect(last_response.status).to eq 200

    get "/projects/skynet/production/builds/2"
    expect(last_response.status).to eq 404
  end
end
