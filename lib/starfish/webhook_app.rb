require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/github/:project' do
      event = env["HTTP_X_GITHUB_EVENT"]

      case event
      when "ping" then status 200
      when "push" then
        payload = JSON.parse(request.body.read)

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

        @project = $repo.find_project(slug: params[:project])
        @pipelines = @project.find_pipelines(branch: branch)

        @pipelines.each do |pipeline|
          pipeline.add_build(commits: commits, author: author)
        end

        $repo.persist!

        status 200
      end
    end
  end
end
