require 'sinatra/base'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/github/:project/:pipeline' do
      event = request.headers["X-GitHub-Event"]

      case event
      when "ping" then status 200
      when "push" then
        @project = $repo.find_project(slug: params[:project])
        @pipeline = @project.find_pipeline(slug: params[:pipeline])

        commits = params[:commits].map {|data|
          Commit.new(
            sha: data[:sha],
            author: data[:author][:name],
            message: data[:message]
          )
        }

        @pipeline.add_build(commits: commits)

        status 200
      end
    end
  end
end
