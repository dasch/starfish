module Starfish
  module FlashHelpers
    def flash(message = nil)
      if message
        session[:flash] = message
      else
        message = session.delete(:flash)
      end

      message
    end

    def flash?
      session[:flash] != nil
    end
  end
end
