module Starfish
  class GithubSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def github_pull_request_opened(timestamp, data)
      project = @repo.find_project(data[:project_id])
      target_branch = data[:target_branch]
      pr = data[:pull_request]

      if project.has_pipeline_for_branch?(target_branch)
        pipeline = project.find_pipeline_by_branch(target_branch)

        pipeline.add_pull_request(
          number: pr[:number],
          title: pr[:title],
          author: User.new(
            username: pr[:author][:username],
            avatar_url: pr[:author][:avatar_url]
          )
        )
      end
    end

    def github_pull_request_closed(timestamp, data)
      project = @repo.find_project(data[:project_id])
      target_branch = pr[:base][:ref]

      if project.has_pipeline_for_branch?(target_branch)
        pipeline = project.find_pipeline_by_branch(target_branch)

        if pull_request = pipeline.find_pull_request(pr[:number]) rescue nil
          pull_request.close!
        end
      end
    end

    def github_status_changed(timestamp, data)
      project = @repo.find_project(data[:project_id])
      status = data[:status]

      value_mapping = {
        "pending" => :pending,
        "success" => :ok,
        "failure" => :failed,
        "error"   => :failed,
      }

      value = value_mapping.fetch(status[:state])

      project.find_builds_by_sha(status[:sha]).each do |build|
        build.update_status(
          context: status[:context],
          value: value,
          description: status[:description],
          url: status[:target_url],
          timestamp: timestamp
        )
      end
    end
  end
end
