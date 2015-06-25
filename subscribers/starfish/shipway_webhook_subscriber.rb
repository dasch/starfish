module Starfish
  class ShipwayWebhookSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.data)
      end
    end

    def docker_build_finished(data)
      project = @repo.find_project(data.fetch(:project_id))
      commit_sha = data.fetch(:commit_sha)
      build_number = data.fetch(:build_number)

      builds = project.find_builds_by_sha(commit_sha)

      builds.each do |build|
        build.add_docker_build(
          image_id: data.fetch(:image_id),
          status: data.fetch(:status),
          build_url: "https://shipway.io/#{project.repo}/builds/#{build_number}"
        )
      end
    end
  end
end
