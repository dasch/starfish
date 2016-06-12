require 'starfish/base_app'

module Starfish
  class EnvironmentApp < BaseApp
    get '/:environment' do
      @environment = $repo.find_environment_by_name(params[:environment])

      erb :show_environment
    end
  end
end
