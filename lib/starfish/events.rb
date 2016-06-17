module EventStruct
  def self.new(event_name)
    schema_name = "starfish.events.#{event_name}"
    Avromatic::Model.model(schema_name: schema_name)
  end
end

BuildAutomaticallyReleased = EventStruct.new("build_automatically_released")
BuildPushed = EventStruct.new("build_pushed")
BuildReleased = EventStruct.new("build_released")
ChannelAdded = EventStruct.new("channel_added")
ChannelConfigKeyAdded = EventStruct.new("channel_config_key_added")
ChannelConfigValueChanged = EventStruct.new("channel_config_value_changed")
ChannelSettingsUpdated = EventStruct.new("channel_settings_updated")
ConfigChangeReleased = EventStruct.new("config_change_released")
DockerBuildFinished = EventStruct.new("docker_build_finished")
GithubHookCreated = EventStruct.new("github_hook_created")
GithubPullRequestOpened = EventStruct.new("github_pull_request_opened")
GithubStatusChanged = EventStruct.new("github_status_changed")
PipelineAdded = EventStruct.new("pipeline_added")
PipelineRemoved = EventStruct.new("pipeline_removed")
ProjectAdded = EventStruct.new("project_added")
ProjectRenamed = EventStruct.new("project_renamed")
ReleaseDeployed = EventStruct.new("release_deployed")
RollbackReleased = EventStruct.new("rollback_released")
