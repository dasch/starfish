require 'starfish/kubernetes'

module Starfish
  class Kubernetes
    class BuildJob
      DOCKER_IMAGE = "dasch/builder:latest"

      def initialize(kubernetes:, repository:, commit_id:)
        @kubernetes = kubernetes
        @repository = repository
        @commit_id = commit_id
        @pod_name = "build-job-#{rand(10000)}"
      end

      def start
        pod = @kubernetes.create_pod(pod_spec)

        @kubernetes.watch_pods(pod.metadata.resourceVersion).each do |event|
          next unless event.object.metadata.name == @pod_name

          if event.object.status.phase == "Succeeded"
            break
          end
        end
      end

      private

      def pod_spec
        pod = Kubeclient::Pod.new

        pod.metadata = {
          name: @pod_name,
          namespace: "dasch",
        }

        pod.spec = {
          restartPolicy: "OnFailure",
          containers: [container_spec],
          volumes: [volume_spec],
        }

        pod
      end

      def container_spec
        {
          name: "builder",
          image: DOCKER_IMAGE,
          command: ["/build.sh", @repository, "test"],
          volumeMounts: [
            {
              mountPath: "/var/run/docker.sock",
              name: "docker-volume",
            }
          ]
        }
      end

      def volume_spec
        {
          name: "docker-volume",
          hostPath: {
            path: "/var/run/docker.sock",
          }
        }
      end
    end
  end
end
