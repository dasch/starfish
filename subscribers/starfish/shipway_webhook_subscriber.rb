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

    def shipway_build_finish_received(data)
      project = @repo.find_project(data[:project_id])
      payload = data[:payload]
      commit_sha = payload["commit"]["sha"]
      build_number = payload["build"]["build_num"]

      builds = project.find_builds_by_sha(commit_sha)

      builds.each do |build|
        build.add_docker_build(
          image_id: payload["images"].first["id"],
          status: payload["build"]["status"],
          build_url: "https://shipway.io/#{project.repo}/builds/#{build_number}"
        )
      end
    end
  end
end
