module Starfish
  class GithubEventHandler
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    # For backwards compatibility.
    def github_webhook_received(timestamp, data)
      github_push_received(timestamp, data)
    end

    def github_push_received(timestamp, data)
      project = @repo.find_project(data[:project_id])
      payload = data[:payload]

      commits = payload["commits"].map {|data|
        author = User.new(
          name: data["author"]["name"],
          username: data["author"]["username"]
        )

        Commit.new(
          sha: data["id"],
          author: author,
          message: data["message"],
          added: data["added"],
          removed: data["removed"],
          modified: data["modified"],
          url: data["url"]
        )
      }

      return if commits.empty?

      author = User.new(
        username: payload["sender"]["login"],
        avatar_url: payload["sender"]["avatar_url"],
      )

      branch = payload["ref"].scan(%r(refs/heads/(.+))).flatten.first

      pipelines = project.find_pipelines(branch: branch)

      pipelines.each do |pipeline|
        pipeline.add_build(commits: commits, author: author)
      end
    end

    def github_pull_request_received(timestamp, data)
      project = @repo.find_project(data[:project_id])
      payload = data[:payload]
      pr = payload["pull_request"]

      case payload["action"]
      when "opened"
        target_branch = pr["base"]["ref"]
        pipelines = project.find_pipelines(branch: target_branch)

        author = User.new(
          username: pr["user"]["login"],
          avatar_url: pr["user"]["avatar_url"]
        )

        pipelines.each do |pipeline|
          pipeline.add_pull_request(
            number: pr["number"],
            title: pr["title"],
            author: author
          )
        end
      when "closed"
        target_branch = pr["base"]["ref"]
        pipelines = project.find_pipelines(branch: target_branch)

        pipelines.each do |pipeline|
          pipeline.remove_pull_request(pr["number"])
        end
      end
    end

    def github_status_received(timestamp, data)
      project = @repo.find_project(data[:project_id])
      payload = data[:payload]

      value_mapping = {
        "pending" => :pending,
        "success" => :ok,
        "failure" => :failed,
        "error"   => :failed,
      }

      value = value_mapping.fetch(payload["state"])

      project.find_builds_by_sha(payload["sha"]).each do |build|
        build.add_status(
          name: payload["context"],
          value: value
        )
      end
    end
  end
end