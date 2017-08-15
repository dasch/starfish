require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'
require 'octokit'

module Starfish
  class SetupApp < Sinatra::Base
    GITHUB_EVENTS = %w[
      status
      push
      pull_request
      pull_request_review
      pull_request_review_comment
      issue_comment
    ]

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
      id = SecureRandom.uuid

      $events.record(:project_added, {
        id: id,
        name: params[:name],
        repo: params[:repo],
        owner: current_user
      })

      @project = $repo.find_project(id)

      $events.record(:pipeline_added, {
        id: SecureRandom.uuid,
        name: "master",
        branch: "master",
        project_id: @project.id,
        author: current_user,
      })

      begin
        secret = SecureRandom.hex

        hook = @github.create_hook(@project.repo, "web", {
          url: github_webhook_url(@project),
          secret: secret,
          content_type: "json"
        }, {
          events: GITHUB_EVENTS
        })

        $events.record(:github_hook_created, {
          project_id: id,
          hook_id: hook.id,
          secret: secret,
        })
      rescue Octokit::UnprocessableEntity
        # Hook already exists.
      end

      redirect project_path(@project)
    end
  end
end
