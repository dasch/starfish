require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class ShipwayWebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/:project' do
      event = env["HTTP_X_SHIPWAY_EVENT"]
      if respond_to?("handle_#{event}")
        send("handle_#{event}")
      end

      status 200
    end

    def handle_build_finish
      $events.record(:docker_build_finished, {
        project_id: project.id,
        commit_sha: payload.fetch("commit").fetch("sha"),
        status: payload.fetch("build").fetch("status"),
        image_id: payload.fetch("images").first.fetch("id"),
        build_number: payload.fetch("build").fetch("build_num"),
      })
    end

    def project
      @project ||= $repo.find_project_by_slug(params[:project])
    end

    def payload
      @payload ||= JSON.parse(request.body.read)
    end
  end
end
