require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/github/:project/:pipeline' do
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

        @project = $repo.find_project(slug: params[:project])
        @pipeline = @project.find_pipeline(slug: params[:pipeline])
        @pipeline.add_build(commits: commits, author: author)

        status 200
      end
    end
  end
end
