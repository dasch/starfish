require 'sinatra/base'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/github/:project/:pipeline' do
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
