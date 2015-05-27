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

    def pipeline_path(pipeline)
      [project_path(pipeline.project), pipeline.slug].join("/")
    end

    def builds_path(pipeline)
      [pipeline_path(pipeline), "builds"].join("/")
    end

    def channels_path(pipeline)
      [pipeline_path(pipeline), "channels"].join("/")
    end

    def channel_path(channel)
      [channels_path(channel.pipeline), channel.slug].join("/")
    end

    def canaries_path(pipeline)
      [pipeline_path(pipeline), "canaries"].join("/")
    end

    def releases_path(channel)
      [channel_path(channel), "releases"].join("/")
    end

    def release_path(release)
      [channel_path(release.channel), release.number].join("/")
    end

    def build_path(build)
      [pipeline_path(build.pipeline), "builds", build.number].join("/")
    end

    def github_webhook_url(pipeline)
      [request.base_url, "webhooks", "github", pipeline.project.slug, pipeline.slug].join("/")
    end
  end
end
