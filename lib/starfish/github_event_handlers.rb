module Starfish
  class GithubEventHandlers
    def initialize(events)
      @events = events
    end

    def handle(project, event)
      handler = "handle_#{event.type.underscore}"

      if respond_to?(handler)
        puts "handling event #{handler}"
        send(handler, project, event)
      end
    end

    def handle_push_event(project, payload)
      branch = payload["ref"].scan(%r(refs/heads/(.+))).flatten.first

      return if payload["commits"].empty?

      if project.has_pipeline_for_branch?(branch)
        pipeline = project.find_pipeline_by_branch(branch)

        author = {
          username: payload["sender"]["login"],
          email: payload["pusher"]["email"],
          avatar_url: payload["sender"]["avatar_url"],
        }

        @events.record(:build_pushed, {
          id: SecureRandom.uuid,
          build_number: pipeline.builds.count + 1,
          project_id: project.id,
          pipeline_id: pipeline.id,
          commits: payload["commits"].map {|c| map_commit(c) },
          head_commit: map_commit(payload["head_commit"]),
          author: author,
        })
      end
    end

    def handle_pull_request_event(project, payload)
      pr = payload["pull_request"]
      target_branch = pr["base"]["ref"]

      if project.has_pipeline_for_branch?(target_branch)
        case payload["action"]
        when "opened"
          @events.record(:github_pull_request_opened, {
            project_id: project.id,
            target_branch: target_branch,
            pull_request: map_pull_request(pr),
          })
        when "closed"
          @events.record(:github_pull_request_closed, {
            project_id: project.id,
            target_branch: target_branch,
            pull_request: map_pull_request(pr),
          })
        end
      end
    end

    def handle_status_event(project, payload)
      @events.record(:github_status_changed, {
        project_id: project.id,
        status: {
          state: payload["state"],
          context: payload["context"],
          description: payload["description"],
          url: payload["target_url"],
          timestamp: Time.now
        },
      })
    end
  end
end
