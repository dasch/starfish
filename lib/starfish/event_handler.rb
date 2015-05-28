module Starfish
  class EventHandler
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      else
        $stderr.puts "Unknown event `#{event.name}`"
      end
    end

    def project_added(timestamp, data)
      project = $repo.add_project(
        id: data[:id],
        name: data[:name],
        repo: data[:repo]
      )

      $stderr.puts "Added project #{project}"
    end

    def build_released(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])
      channel = pipeline.find_channel(data[:channel_id])

      build = pipeline.find_build(number: data[:build_number])
      config = channel.find_config(version: data[:config_version])
      author = data[:author]

      release = channel.add_release(
        id: data[:id],
        build: build,
        config: config,
        author: author
      )

      $stderr.puts "Added release #{release}"
    end

    def pipeline_added(timestamp, data)
      project = @repo.find_project(data[:project_id])

      pipeline = project.add_pipeline(
        id: data[:id],
        name: data[:name],
        branch: data[:branch]
      )

      $stderr.puts "Added pipeline #{pipeline}"
    end

    def channel_added(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      channel = pipeline.add_channel(
        id: data[:id],
        name: data[:name],
        auto_release_builds: data[:auto_release_builds]
      )

      $stderr.puts "Added channel #{channel}"
    end

    def github_webhook_received(timestamp, data)
      project = $repo.find_project(data[:project_id])
      payload = data[:payload]

      commits = payload["commits"].map {|data|
        author = User.new(
          name: data["author"]["name"],
          username: data["author"]["username"]
        )

        Commit.new(
          sha: data["id"],
          author: author,
          message: data["message"]
        )
      }

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
  end
end
