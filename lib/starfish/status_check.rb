module Starfish
  class StatusCheck
    CONTEXT_NAMES = {
      "ci/circleci" => "CircleCI",
      "continuous-integration/codeship" => "Codeship",
      "continuous-integration/travis-ci/push" => "Travis CI",
      "codeclimate" => "Code Climate",
      "semaphoreci" => "Semaphore CI",
    }

    attr_reader :context, :value, :description, :created_at, :updated_at, :url

    def initialize(context:, url:, created_at:)
      @context = context
      @created_at = created_at
      @updated_at = created_at
      @description = name
      @url = url
      @value = :pending
    end

    def name
      CONTEXT_NAMES.fetch(context, context)
    end

    def update(value, description:, timestamp:)
      @value = value
      @description = description
      @updated_at = timestamp
    end

    def ok?
      value == :ok
    end

    def pending?
      value == :pending
    end

    def failed?
      value == :failed
    end
  end
end
