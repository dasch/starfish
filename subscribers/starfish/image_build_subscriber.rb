require 'starfish/kubernetes'

module Starfish
  class ImageBuildSubscriber
    def initialize(repo)
      @repo = repo
      @kubernetes = Kubernetes.new
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def build_pushed(timestamp, data)
      project = @repo.find_project(data.fetch(:project_id))
      pipeline = project.find_pipeline(data.fetch(:pipeline_id))
      build = pipeline.find_build(data.fetch(:id))

      @kubernetes.build(build)
    end
  end
end
