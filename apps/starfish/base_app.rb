require 'sinatra/base'
require 'sinatra/namespace'

require 'starfish/authentication_helpers'
require 'starfish/flash_helpers'
require 'starfish/url_helpers'
require 'starfish/not_found'

module Starfish
  class BaseApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    use Rack::MethodOverride

    register Sinatra::Namespace

    before do
      redirect "/auth/signin" if session[:auth].nil?
      @projects = $repo.projects
      @environments = $repo.environments
    end

    helpers AuthenticationHelpers, UrlHelpers, FlashHelpers

    helpers do
      def change_status(status)
        case status
        when :added then '<span class="label label-success">A</span>'
        when :removed then '<span class="label label-danger">R</span>'
        when :modified then '<span class="label label-primary">M</span>'
        end
      end

      def relative_time(timestamp)
        <<-HTML.strip
          <time class="relative" datetime="#{timestamp.iso8601}">
            #{timestamp}
          </time>
        HTML
      end

      def pipeline_nav_items(pipeline)
        items = {
          "Builds"        => builds_path(pipeline),
          "Channels"      => channels_path(pipeline),
          "Config"        => pipeline_config_path(pipeline),
          "Processes"     => processes_path(pipeline),
          "Settings"      => pipeline_settings_path(pipeline),
        }

        active_path = items.values.
          select {|path| current_path.start_with?(path) }.
          max_by(&:length)

        items.map do |title, path|
          [title, path, path == active_path]
        end
      end

      def release_event(release)
        release.author.to_s + " " +
          erb(release.event_name, locals: { event: release.event })
      end

      def status_indicator(status)
        classes = "glyphicon-"
        classes << "ok text-success" if status.ok?
        classes << "remove text-danger" if status.failed?
        classes << "refresh text-info" if status.pending?

        %(<span class="glyphicon #{classes}" aria-hidden="true"></span>)
      end
    end

    error NotFound do
      status 404

      "Page not found"
    end
  end
end
