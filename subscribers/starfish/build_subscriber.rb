require 'starfish/event_subscriber'

module Starfish
  class BuildSubscriber < EventSubscriber
    def initialize(repo)
      @repo = repo
    end

    def build_pushed(timestamp, event)
      project = @repo.find_project(event.project_id)
      pipeline = project.find_pipeline(event.pipeline_id)

      commits = event.commits.map {|c| map_commit(c) }
      commits << map_commit(event.head_commit) if commits.empty?

      author = User.new(
        username: event.author.username,
        avatar_url: event.author.avatar_url,
      )

      build = pipeline.add_build(
        id: event.id,
        number: event.build_number,
        commits: commits,
        author: author,
        timestamp: timestamp,
      )

      if commits.any? && commits.last.message =~ /Merge pull request #(\d+) from/
        build.pull_request = pipeline.find_pull_request($1.to_i) rescue nil
      end
    end

    private

    def map_commit(c)
      author = User.new(
        name: c.author.name,
        username: c.author.username,
      )

      Commit.new(
        sha: c.sha,
        author: author,
        message: c.message,
        added: c.added,
        removed: c.removed,
        modified: c.modified,
        url: c.url
      )
    end
  end
end
