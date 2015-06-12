require 'starfish/base_app'

module Starfish
  class BuildApp < BaseApp
    namespace '/:project/:pipeline/builds/:build' do
      helpers do
        def commit_link(commit)
          %(<a href="#{commit.url}"><code>#{commit.sha}</code></a>)
        end
      end

      before do
        @project = $repo.find_project_by_slug(params[:project])
        @pipeline = @project.find_pipeline_by_slug(params[:pipeline])
        @build = @pipeline.find_build_by_number(params[:build].to_i)
      end

      get '' do
        erb :build_layout do
          erb :show_build
        end
      end

      get '/changes' do
        erb :build_layout do
          erb :show_build_changes
        end
      end

      get '/commits' do
        erb :build_layout do
          erb :show_build_commits
        end
      end
    end
  end
end
