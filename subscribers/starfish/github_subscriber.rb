module Starfish
  class GithubSubscriber
    def initialize(repo)
      @repo = repo
      @handled_events = Hash.new {|h, k| h[k] = Set.new }
    end

    def update(event)
      if respond_to?(event.name)
        event_id = event.data[:event_id]
        project_id = event.data[:project_id]

        if @handled_events[project_id].include?(event_id)
          $logger.warn "Already handled GitHub event #{event_id}"
        else
          send(event.name, event.timestamp, event.data)
          @handled_events[project_id].add(event_id)
        end
      end
    end

    def build_added(timestamp, data)
      project = @repo.find_project(data.fetch(:project_id))
      branch = data.fetch(:branch)

      pipeline = project.find_pipeline_by_branch(branch)

      commits = data[:commits].map {|data|
        author = User.new(
          name: data[:author][:name],
          username: data[:author][:username]
        )

        Commit.new(
          sha: data[:id],
          author: author,
          message: data[:message],
          added: data[:added],
          removed: data[:removed],
          modified: data[:modified],
          url: data[:url]
        )
      }

      author = User.new(
        username: data[:username],
        avatar_url: data[:avatar_url]
      )

      build = pipeline.add_build(
        id: SecureRandom.uuid,
        commits: commits,
        author: author
      )

      if data[:commits].last[:message] =~ /Merge pull request #(\d+) from/
        build.pull_request = pipeline.find_pull_request($1.to_i) rescue nil
      end
    end

    def github_pull_request_received(timestamp, data)
      project = @repo.find_project(data[:project_id])
      payload = data[:payload]
      pr = payload["pull_request"]

      case payload["action"]
      when "opened"
        target_branch = pr["base"]["ref"]

        if project.has_pipeline_for_branch?(target_branch)
          pipeline = project.find_pipeline_by_branch(target_branch)

          author = User.new(
            username: pr["user"]["login"],
            avatar_url: pr["user"]["avatar_url"]
          )

          pipeline.add_pull_request(
            number: pr["number"],
            title: pr["title"],
            author: author
          )
        end
      when "closed"
        target_branch = pr["base"]["ref"]

        if project.has_pipeline_for_branch?(target_branch)
          pipeline = project.find_pipeline_by_branch(target_branch)

          if pull_request = pipeline.find_pull_request(pr["number"]) rescue nil
            pull_request.close!
          end
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
          context: payload["context"],
          value: value,
          description: payload["description"],
          url: payload["target_url"],
          timestamp: timestamp
        )
      end
    end
  end
end
