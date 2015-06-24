require 'sinatra/base'
require 'active_support/cache'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class GithubWebhookApp < Sinatra::Base
    CACHE = ActiveSupport::Cache::MemoryStore.new

    set :root, File.expand_path("../../../", __FILE__)

    post '/:project' do
      event = env["HTTP_X_GITHUB_EVENT"]

      if respond_to?("handle_#{event}")
        authenticate_webhook!
        send("handle_#{event}") unless event_already_handled?
        mark_event_as_handled!
      end

      status 200
    end

    def handle_push
      branch = payload["ref"].scan(%r(refs/heads/(.+))).flatten.first

      return if payload["commits"].empty?

      if project.has_pipeline_for_branch?(branch)
        pipeline = project.find_pipeline_by_branch(branch)

        author = {
          username: payload["sender"]["login"],
          email: payload["pusher"]["email"],
          avatar_url: payload["sender"]["avatar_url"],
        }

        $events.record(:build_pushed, {
          id: SecureRandom.uuid,
          build_number: pipeline.builds.count + 1,
          project_id: project.id,
          pipeline_id: pipeline.id,
          commits: payload["commits"].map {|c| map_commit(c) },
          head_commit: map_commit(payload["head_commit"]),
          author: author,
        })
      end
    end

    def handle_pull_request
      pr = payload["pull_request"]
      target_branch = pr["base"]["ref"]

      if project.has_pipeline_for_branch?(target_branch)
        case payload["action"]
        when "opened"
          $events.record(:github_pull_request_opened, {
            project_id: project.id,
            target_branch: target_branch,
            pull_request: map_pull_request(pr),
          })
        when "closed"
          $events.record(:github_pull_request_closed, {
            project_id: project.id,
            target_branch: target_branch,
            pull_request: map_pull_request(pr),
          })
        end
      end
    end

    def handle_status
      $events.record(:github_status_changed, {
        project_id: project.id,
        status: {
          state: payload["state"],
          context: payload["context"],
          description: payload["description"],
          url: payload["target_url"],
          timestamp: Time.now
        },
      })
    end

    private

    def authenticate_webhook!
      signature = env["HTTP_X_HUB_SIGNATURE"]

      if signature != compute_signature
        $logger.error "Invalid GitHub signature: #{signature}"
        halt 401
      end
    end

    def compute_signature
      secret = project.github_webhook_secret
      digest = OpenSSL::Digest.new('sha1')

      'sha1=' << OpenSSL::HMAC.hexdigest(digest, secret, request_body)
    end

    def map_commit(data)
      {
        sha: data["id"],
        author: {
          name: data["author"]["name"],
          email: data["author"]["email"],
          username: data["author"]["username"]
        },
        committer: {
          name: data["committer"]["name"],
          email: data["committer"]["email"],
          username: data["committer"]["username"]
        },
        message: data["message"],
        added: data["added"],
        removed: data["removed"],
        modified: data["modified"],
        url: data["url"],
      }
    end

    def map_pull_request(pr)
      {
        number: pr["number"],
        state: pr["state"],
        title: pr["title"],
        body: pr["body"],
        created_at: pr["created_at"],
        author: {
          username: pr["user"]["login"],
          avatar_url: pr["user"]["avatar_url"],
        },
        head: {
          label: pr["head"]["label"],
          ref: pr["head"]["ref"],
          sha: pr["head"]["sha"],
        },
        base: {
          label: pr["base"]["label"],
          ref: pr["base"]["ref"],
          sha: pr["base"]["sha"],
        },
      }
    end

    def event_already_handled?
      CACHE.read(event_key) != nil
    end

    def mark_event_as_handled!
      CACHE.write(event_key, true)
    end

    def event_key
      [project.id, event_id].join(":")
    end

    def event_id
      env["HTTP_X_GITHUB_DELIVERY"]
    end

    def project
      @project ||= $repo.find_project_by_slug(params[:project])
    end

    def payload
      @payload ||= JSON.parse(request_body)
    end

    def request_body
      @body ||= request.body.read
    end
  end
end
