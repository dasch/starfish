module Starfish
  module AuthenticationHelpers
    class AuthenticatedUser
      attr_reader :email, :name, :nickname

      def initialize(email:, name:, nickname:)
        @email = email
        @name = name
        @nickname = nickname
      end
    end

    def current_user
      @current_user ||= AuthenticatedUser.new(
        email: session[:auth].info.email,
        name: session[:auth].info.name,
        nickname: session[:auth].info.nickname
      )
    end
  end
end
