require 'sinatra/base'
require 'json'
require 'starfish/url_helpers'

module Starfish
  class ShipwayWebhookApp < Sinatra::Base
    EVENTS = %w(build_finish).freeze

    set :root, File.expand_path("../../../", __FILE__)

    post '/:project' do
      event_id = env["HTTP_X_SHIPWAY_DELIVERY"]
      event = env["HTTP_X_SHIPWAY_EVENT"]
      project = $repo.find_project_by_slug(params[:project])
      payload = JSON.parse(request.body.read)

      if EVENTS.include?(event)
        $events.record(:"shipway_#{event}_received", {
          event_id: event_id,
          project_id: project.id,
          payload: payload
        })
      end

      status 200
    end
  end
end
