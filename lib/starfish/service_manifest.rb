require 'json'
require 'base64'

module Starfish
  class ServiceManifest
    class Process
      attr_reader :name, :command

      def initialize(name:, command:)
        @name = name
        @command = command
      end
    end

    def initialize(project, branch:, github_token:)
      @project = project
      @branch = branch
      @github_token = github_token
    end

    def processes
      manifest ? manifest["roles"].map {|name, data| Process.new(name: name, command: data["command"]) } : []
    end

    private

    def manifest
      @manifest ||= load_manifest
    end

    def load_manifest
      file = github.contents(@project.repo, path: "manifest.json", ref: @branch)
      JSON.parse(Base64.decode64(file.content))
    rescue Octokit::NotFound
      nil
    end

    def github
      @github ||= Octokit::Client.new(
        access_token: @github_token
      )
    end
  end
end
