require 'starfish/kubernetes'

module Starfish
  class Kubernetes
    class BuildJob
      DOCKER_IMAGE = "dasch/builder:latest"

      attr_reader :status

      def initialize(kubernetes:, build:)
        @kubernetes = kubernetes
        @build = build
        @project = build.pipeline.project
        @pod_name = "build-job-#{rand(10000)}"
      end

      def start
        pod = @kubernetes.create_pod(pod_spec)

        @kubernetes.watch_pods(pod.metadata.resourceVersion).each do |event|
          next unless event.object.metadata.name == @pod_name

          case event.object.status.phase
          when "Succeeded"
            @status = :succeeded
            break
          when "Failed"
            @status = :failed
            break
          when "Pending"
            @status = :pending
          when "Running"
            @status = :running
          end
        end

      ensure
        @kubernetes.delete_pod(@pod_name, Kubernetes::NAMESPACE)
      end

      private

      def pod_spec
        pod = Kubeclient::Pod.new

        pod.metadata = {
          name: @pod_name,
          namespace: NAMESPACE,
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
          command: ["/build.sh", @project.repo_url, @build.image_tag],
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
