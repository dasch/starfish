module Starfish
  module UserHelpers
    def avatar_for(username)
      user = @project.find_user(username.to_s)
      erb :avatar, locals: { user: user }
    end
  end
end
