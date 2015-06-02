module Starfish
  module UrlHelpers
    def setup_path
      "/setup"
    end

    def authentication_path
      "/auth/github"
    end

    def projects_path
      "/projects"
    end

    def project_path(project)
      ["/projects", project.slug].join("/")
    end

    def pipelines_path(project)
      [project_path(project), "pipelines"].join("/")
    end

    def pipeline_path(pipeline)
      [project_path(pipeline.project), pipeline.slug].join("/")
    end

    def builds_path(pipeline)
      [pipeline_path(pipeline), "builds"].join("/")
    end

    def pulls_path(pipeline)
      [pipeline_path(pipeline), "pulls"].join("/")
    end

    def pull_path(pull)
      [pulls_path(pull.pipeline), pull.number].join("/")
    end

    def pipeline_config_path(pipeline)
      [pipeline_path(pipeline), "config"].join("/")
    end

    def processes_path(pipeline)
      [pipeline_path(pipeline), "processes"].join("/")
    end

    def channels_path(pipeline)
      [pipeline_path(pipeline), "channels"].join("/")
    end

    def channel_path(channel)
      [channels_path(channel.pipeline), channel.slug].join("/")
    end

    def channel_settings_path(channel)
      [channel_path(channel), "settings"].join("/")
    end

    def config_path(channel)
      [channel_path(channel), "config"].join("/")
    end

    def config_keys_path(channel)
      [channel_path(channel), "config", "keys"].join("/")
    end

    def canaries_path(pipeline)
      [pipeline_path(pipeline), "canaries"].join("/")
    end

    def releases_path(channel)
      [channel_path(channel), "releases"].join("/")
    end

    def release_rollbacks_path(channel)
      [channel_path(channel), "releases", "rollbacks"].join("/")
    end

    def release_path(release)
      [channel_path(release.channel), release.number].join("/")
    end

    def build_path(build)
      [pipeline_path(build.pipeline), "builds", build.number].join("/")
    end

    def build_changes_path(build)
      [build_path(build), "changes"].join("/")
    end

    def build_commits_path(build)
      [build_path(build), "commits"].join("/")
    end

    def github_webhook_url(project)
      [request.base_url, "webhooks", "github", project.slug].join("/")
    end
  end
end
