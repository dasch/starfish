module Starfish
  module Flowdock
    class NotificationTarget
      # We want every replay to start a new thread.
      NAMESPACE = ENV["RACK_ENV"] == "development" ? SecureRandom.hex(12) : "starfish"

      attr_reader :slug

      def initialize(slug:, source_id:, flow_token:)
        @slug = slug
        @source_id = source_id
        @flow_token = flow_token
      end

      def notify(event_name, **data)
        if respond_to?(event_name)
          send(event_name, **data)
        end
      end

      def build_added(build:)
        post_message(
          title: "pushed build #{build}",
          author: build.author,
          build: build
        )
      end

      def release_added(release:)
        post_message(
          title: "released to #{release.channel}",
          author: release.author,
          build: release.build
        )
      end

      def to_s
        "Flowdock: #{slug}"
      end

      private

      def post_message(author:, build:, title:)
        pipeline = build.pipeline
        project = pipeline.project

        payload = {
          flow_token: @flow_token,
          event: "activity",
          author: {
            name: author.username,
            avatar: author.avatar_url
          },
          title: title,
          external_thread_id: "#{NAMESPACE}:build:#{build.number}",
          thread: {
            title: "#{project} / #{pipeline}: Build #{build}"
          }
        }

        response = Flowdock::Client.post("/messages", body: payload)

        if response.success?
          $logger.info "Sent Flowdock notification"
        else
          $logger.error "Failed to send Flowdock notification:\n#{response}"
        end
      end
    end
  end
end
