require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class GithubWebhookApp < Sinatra::Base
    HANDLED_EVENTS = Set.new

    set :root, File.expand_path("../../../", __FILE__)

    post '/:project_id' do
      if respond_to?("handle_#{event}") && !already_handled?
        send("handle_#{event}")
      end

      status 200
    end

    private

    def handle_push
      commits = payload["commits"].map {|data|
        {
          sha: data["id"],
          author: {
            name: data["author"]["name"],
            username: data["author"]["username"]
          },
          message: data["message"],
          added: data["added"],
          removed: data["removed"],
          modified: data["modified"],
          url: data["url"]
        }
      }

      author = {
        username: payload["sender"]["login"],
        avatar_url: payload["sender"]["avatar_url"],
      }

      branch = payload["ref"].scan(%r(refs/heads/(.+))).flatten.first

      handler.add_build(
        branch: branch,
        commits: commits,
        author: author
      )
    end

    def event_id
      env["HTTP_X_GITHUB_DELIVERY"]
    end

    def event
      env["HTTP_X_GITHUB_EVENT"]
    end

    def already_handled?
      event_id && HANDLED_EVENTS.include?(event_id)
    end

    def payload
      @payload ||= JSON.parse(request.body.read)
    end

    def handler
      @handler ||= ProjectHandler.find(params[:project_id])
    end
  end
end
