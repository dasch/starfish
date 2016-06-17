require 'starfish/event_subscriber'

module Starfish
  class ShipwayWebhookSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def docker_build_finished(timestamp, event)
      project = @repo.find_project(event.project_id)
      commit_sha = event.commit_sha
      build_number = event.build_number

      builds = project.find_builds_by_sha(commit_sha)

      builds.each do |build|
        build.add_docker_build(
          image_id: event.image_id,
          status: event.status,
          build_url: "https://shipway.io/#{project.repo}/builds/#{build_number}"
        )
      end
    end
  end
end
