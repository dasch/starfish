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

    before do
      @github = Octokit::Client.new(
        access_token: session[:auth].credentials.token
      )

      # Load collections in their entirety rather than just the first page.
      @github.auto_paginate = true
    end

    get '/' do
      @repos = @github.repositories

      erb :select_github_repo
    end

    post '/' do
      aggregate = ProjectAggregate.new

      id = aggregate.add_project(
        name: params[:name],
        repo: params[:repo]
      )

      @project = $repo.find_project(id)

      begin
        @github.create_hook(@project.repo, "web", {
          url: github_webhook_url(@project),
          content_type: "json"
        }, {
          events: %w[status push pull_request pull_request_review_comment issue_comment]
        })
      rescue Octokit::UnprocessableEntity
        # Hook already exists.
      end

      redirect project_path(@project)
    end
  end
end
