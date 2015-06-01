require 'sinatra/base'
require 'starfish/authentication_helpers'
require 'starfish/url_helpers'
require 'starfish/not_found'

module Starfish
  class EnvironmentApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "project") }

    helpers AuthenticationHelpers, UrlHelpers

    error NotFound do
      "Page not found"
    end

    before do
      @environments = $repo.environments
      @projects = $repo.projects
    end

    get '/:environment' do
      @environment = $repo.find_environment_by_slug(params[:environment])

      erb :list_pods
    end
  end
end
