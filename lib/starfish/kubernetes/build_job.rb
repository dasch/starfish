require 'starfish/kubernetes'

module Starfish
  class Kubernetes
    class BuildJob
      DOCKER_IMAGE = "dasch/builder:latest"

      def initialize(kubernetes:, repository:, commit_id:)
        @kubernetes = kubernetes
        @repository = repository
        @commit_id = commit_id
      end

      def start
        pod = pod_spec
        @kubernetes.create_pod(pod)
      end

      private

      def pod_spec
        pod = Kubeclient::Pod.new

        pod.metadata = {
          name: "builder",
          namespace: "dasch",
        }

        pod.spec = {
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
