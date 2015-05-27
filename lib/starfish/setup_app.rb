require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'
require 'octokit'

module Starfish
  class SetupApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "setup") }

    set :github_client_id, ENV.fetch("GITHUB_CLIENT_ID")
    set :github_client_secret, ENV.fetch("GITHUB_CLIENT_SECRET")

    helpers AuthenticationHelpers, UrlHelpers

    helpers do
      def setup_repo_path(repo)
        [setup_path, "repo"].join("/") << "?name=#{repo.full_name}"
      end

      def setup_finalize_path
        setup_path
      end
    end

    before do
      @github = Octokit::Client.new(
        access_token: session[:auth].credentials.token
      )
    end

    get '/' do
      @repos = @github.repositories

      erb :select_github_repo
    end

    post '/' do
      @project = $repo.add_project(name: params[:name], repo: params[:repo])

      @pipeline = @project.add_pipeline(
        name: params[:pipeline_name],
        branch: params[:pipeline_branch]
      )

      @github.create_hook(@project.repo, "web", url: github_webhook_url(@pipeline))

      redirect pipeline_path(@pipeline)
    end

    get '/repo' do
      @repo = @github.repository(params[:name])

      erb :define_pipeline
    end
  end
end
