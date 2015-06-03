require 'httparty'

module Starfish
  module Flowdock
    class Client
      include HTTParty

      Error = Class.new(StandardError)

      base_uri "https://api.flowdock.com"

      def initialize(token)
        @token = token
        @headers = {
          "Authorization" => "Bearer #{token}"
        }
      end

      def flows
        response = self.class.get("/flows", headers: @headers)

        if response.success?
          response.map {|data| Flow.new(data) }
        else
          raise Error, response.body
        end
      end

      def add_source(slug, name:, url:)
        response = self.class.post("/flows/#{slug}/sources", headers: @headers, body: {
          name: name,
          external_url: url
        })

        if response.success?
          Source.new(response)
        else
          raise Error, response.body
        end
      end

      class Flow
        attr_reader :slug, :org_slug, :name, :api_token

        def initialize(options = {})
          @slug = options.fetch("parameterized_name")
          @org_slug = options.fetch("organization").fetch("parameterized_name")
          @name = options.fetch("name")
          @api_token = options.fetch("api_token")
        end

        def full_slug
          [org_slug, slug].join("/")
        end

        def to_s
          @name
        end
      end

      class Source
        attr_reader :id, :flow_token

        def initialize(options = {})
          @id = options.fetch("id")
          @flow_token = options.fetch("flow_token")
        end
      end
    end
  end
end
