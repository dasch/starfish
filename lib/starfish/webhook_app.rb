require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class WebhookApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    post '/github/:project' do
      event_id = env["HTTP_X_GITHUB_DELIVERY"]
      event = env["HTTP_X_GITHUB_EVENT"]

      case event
      when "ping" then status 200
      when "push" then
        project = $repo.find_project_by_slug(params[:project])
        payload = JSON.parse(request.body.read)

        $events.record(:github_webhook_received, {
          event_id: event_id,
          project_id: project.id,
          payload: payload
        })

        status 200
      end
    end
  end
end
