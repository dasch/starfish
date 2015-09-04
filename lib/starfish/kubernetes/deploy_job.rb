module Starfish
  class Kubernetes
    class DeployJob
      def initialize(release:, kubernetes:)
        @release = release
        @kubernetes = kubernetes
        @app_name = @release.channel.pipeline.project.slug
        @controller_name = "#{@app_name}-#{@release}"
        @replicas = 4
      end

      def start
        previous_rcs = @kubernetes.get_replication_controllers(
          label_selector: "app=#{@app_name}"
        )

        previous_rcs.each do |rc|
          next unless rc.metadata.namespace == Kubernetes::NAMESPACE
          @kubernetes.delete_replication_controller(rc.metadata.name, Kubernetes::NAMESPACE)
        end

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
            app: @app_name,
          },
          template: pod_spec
        }

        rc
      end

      def pod_spec
        {
          metadata: {
            labels: {
              app: @app_name,
            },
          },
          spec: {
            containers: [container_spec]
          }
        }
      end

      def container_spec
        {
          name: @release.channel.pipeline.project.slug,
          image: @release.build.image_tag,
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
