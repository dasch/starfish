module Starfish
  class BuildSubscriber
    def initialize(repo)
      @repo = repo
    end

    def update(event)
      if respond_to?(event.name)
        send(event.name, event.timestamp, event.data)
      end
    end

    def build_pushed(timestamp, data)
      project = @repo.find_project(data[:project_id])
      pipeline = project.find_pipeline(data[:pipeline_id])

      commits = data[:commits].map {|c|
        author = User.new(
          name: c[:author][:name],
          username: c[:author][:username],
        )

        Commit.new(
          sha: c[:sha],
          author: author,
          message: c[:message],
          added: c[:added],
          removed: c[:removed],
          modified: c[:modified],
          url: c[:url]
        )
      }

      author = User.new(
        username: data[:author][:username],
        avatar_url: data[:author][:avatar_url],
      )

      build = pipeline.add_build(
        id: data.fetch(:id),
        number: data.fetch(:build_number),
        commits: commits,
        author: author
      )

      if commits.last.message =~ /Merge pull request #(\d+) from/
        build.pull_request = pipeline.find_pull_request($1.to_i) rescue nil
      end
    end
  end
end
