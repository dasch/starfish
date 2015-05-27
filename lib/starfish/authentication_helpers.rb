require 'starfish/user'

module Starfish
  module AuthenticationHelpers
    def current_user
      @current_user ||= User.new(
        name: session[:auth].info.name,
        username: session[:auth].info.nickname,
        avatar_url: session[:auth].info.image
      )
    end
  end
end
