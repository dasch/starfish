module Starfish
  class Kubernetes
    class DeployJob
      def initialize(release:, kubernetes:)
        @release = release
        @kubernetes = kubernetes
        @controller_name = "test-controller-#{rand(10000)}"
        @replicas = 4
      end

      def start
        rc = @kubernetes.create_replication_controller(controller_spec)

        @kubernetes.watch_replication_controllers(rc.metadata.resourceVersion).each do |event|
          next unless event.object.metadata.name == @controller_name

          if event.object.status.replicas == @replicas
            break
          end
        end
      end

      private

      def controller_spec
        rc = Kubeclient::ReplicationController.new

        rc.metadata = {
          name: @controller_name,
          namespace: Kubernetes::NAMESPACE,
        }

        rc.spec = {
          replicas: @replicas,
          selector: {
            app: "test",
          },
          template: pod_spec
        }

        rc
      end

      def pod_spec
        {
          metadata: {
            labels: {
              app: "test",
            },
          },
          spec: {
            containers: [container_spec]
          }
        }
      end

      def container_spec
        {
          name: "nginx",
          image: "nginx",
          env: env_spec,
        }
      end

      def env_spec
        @release.config.env.map {|key, value|
          { name: key, value: value }
        }
      end
    end
  end
end
