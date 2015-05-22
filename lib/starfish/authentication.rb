require 'starfish/url_helpers'

module Starfish
  class Authentication < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)

    helpers UrlHelpers

    get '/:provider/callback' do
      session[:auth] = env['omniauth.auth']

      redirect "/"
    end

    get '/signin' do
      erb :signin, layout: false
    end

    get '/signout' do
      session[:auth] = nil

      redirect "/"
    end
  end
end
