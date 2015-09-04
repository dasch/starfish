require 'kubeclient'
require 'starfish/kubernetes/build_job'
require 'starfish/kubernetes/deploy_job'

module Starfish
  class Kubernetes
    NAMESPACE = "dasch"
    KUBERNETES_URL = 'http://localhost:8080/api/'

    def initialize
      @client = Kubeclient::Client.new(KUBERNETES_URL)
    end

    def build(build)
      project = build.pipeline.project

      job = BuildJob.new(
        kubernetes: @client,
        repository: "https://github.com/#{project.repo}.git",
        commit_id: build.sha,
      )

      job.start
    end

    def deploy(release)
      job = DeployJob.new(release: release, kubernetes: @client)
      job.start
    end
  end
end
