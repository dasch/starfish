require 'requests/spec_helper'

describe "Config" do
  before do
    sign_in_with_github
    create_project name: "Skynet", repo: "luke/deathstar"
    create_pipeline project: "skynet", pipeline_name: "Production", pipeline_branch: "master"

    create_channel(
      project: "skynet",
      pipeline: "production",
      channel_name: "Staging",
      channel_auto_release: "1"
    )
  end

  example "adding a new config key" do
    create_config_key(
      project: "skynet",
      pipeline: "production",
      channel: "staging",
      config_key: "RACK_ENV",
      config_value: "production"
    )
  end

  def create_config_key(project:, pipeline:, channel:, **params)
    post "/projects/#{project}/#{pipeline}/channels/#{channel}/config/keys", params
    follow_redirect!
  end
end
