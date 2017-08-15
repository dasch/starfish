require 'starfish/event_subscriber'

module Starfish
  class GithubSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def github_hook_created(timestamp, event)
      project = @repo.find_project(event.project_id)
      project.github_webhook_secret = event.secret
    end

    def github_pull_request_opened(timestamp, event)
      project = @repo.find_project(event.project_id)
      target_branch = event.target_branch
      pr = event.pull_request

      if project.has_pipeline_for_branch?(target_branch)
        pipeline = project.find_pipeline_by_branch(target_branch)

        pipeline.add_pull_request(
          number: pr.number,
          title: pr.title,
          author: User.new(
            username: pr.author.username,
            avatar_url: pr.author.avatar_url
          )
        )
      end
    end

    def github_pull_request_reviewed(timestamp, event)
      project = @repo.find_project(event.project_id)
      target_branch = event.target_branch
      pr_id = event.pull_request_id

      if project.has_pipeline_for_branch?(target_branch)
        pipeline = project.find_pipeline_by_branch(target_branch)

        pr = pipeline.find_pull_request(pr_id)

        pr.add_review(
          state: event.state,
          reviewer: event.reviewer,
        )
      end
    end

    def github_pull_request_closed(timestamp, event)
      project = @repo.find_project(event.project_id)
      target_branch = pr.base.ref

      if project.has_pipeline_for_branch?(target_branch)
        pipeline = project.find_pipeline_by_branch(target_branch)

        if pull_request = pipeline.find_pull_request(pr.number) rescue nil
          pull_request.close!
        end
      end
    end

    def github_status_changed(timestamp, event)
      project = @repo.find_project(event.project_id)
      status = event.status

      value_mapping = {
        "pending" => :pending,
        "success" => :ok,
        "failure" => :failed,
        "error"   => :failed,
      }

      value = value_mapping.fetch(status.state)

      project.find_builds_by_sha(event.sha).each do |build|
        build.update_status(
          context: status.context,
          value: value,
          description: status.description,
          url: status.url,
          timestamp: timestamp
        )
      end
    end
  end
end
