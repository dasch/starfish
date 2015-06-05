require 'starfish/url_helpers'

module Starfish
  class AuthenticationApp < Sinatra::Base
    set :root, File.expand_path("../../../", __FILE__)
    set :views, -> { File.join(root, "views", "authentication") }

    helpers UrlHelpers

    get '/github/callback' do
      session[:auth] = env['omniauth.auth']

      redirect "/"
    end

    get '/flowdock/callback' do
      session[:flowdock_auth] = env['omniauth.auth']

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
