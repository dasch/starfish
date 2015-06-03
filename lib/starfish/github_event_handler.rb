require 'starfish/notification_bus'

module Starfish
  class GithubEventHandler
    def initialize(repo)
      @repo = repo
      @handled_events = Hash.new {|h, k| h[k] = Set.new }
      @notification_bus = NotificationBus.new(@repo)
    end

    def update(event)
      if respond_to?(event.name)
        event_id = event.data[:event_id]
        project_id = event.data[:project_id]

        if @handled_events[project_id].include?(event_id)
          $stderr.puts "Already handled GitHub event #{event_id}"
        else
          send(event.name, event.timestamp, event.data)
          @handled_events[project_id].add(event_id)
        end
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
        build = pipeline.add_build(commits: commits, author: author)

        @notification_bus.notify(pipeline, :build_added, timestamp, build: build)

        pipeline.channels.each do |channel|
          if channel.auto_release_builds?
            release = channel.add_release(
              build: build,
              config: channel.current_config,
              author: author,
              event: AutomaticReleaseEvent.new(build: build)
            )

            @notification_bus.notify(pipeline, :release_added, timestamp, release: release)
          end
        end
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
        build.update_status(
          name: payload["context"],
          value: value,
          description: payload["description"],
          timestamp: timestamp
        )
      end
    end
  end
end
