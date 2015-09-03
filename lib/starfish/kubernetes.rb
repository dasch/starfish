require 'kubeclient'
require 'starfish/kubernetes/build_job'

module Starfish
  class Kubernetes
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
      rc = Kubeclient::ReplicationController.new

      rc.metadata = {
        name: "test-controller",
        namespace: "dasch",
      }

      rc.spec = {
        replicas: 1,
        selector: {
          app: "test",
        },
        template: {
          metadata: {
            labels: {
              app: "test",
            },
          },
          spec: {
            containers: [
              {
                name: "nginx",
                image: "nginx",
              }
            ]
          }
        }
      }

      @client.create_replication_controller(rc)
    end
  end
end
