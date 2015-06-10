require 'starfish/base_app'
require 'starfish/channel_app'
require 'starfish/pipeline_app'
require 'starfish/build_app'

module Starfish
  class ProjectApp < BaseApp
    get '/' do
      @project = @projects.first
      redirect @project ? project_path(@project) : setup_path
    end

    namespace '/:project' do
      before do
        @project = $repo.find_project_by_slug(params[:project])
      end

      get '' do
        @pipeline = @project.pipelines.first
        redirect @pipeline ? pipeline_path(@pipeline) : pipelines_path(@project)
      end

      get '/pipelines' do
        erb :list_pipelines
      end

      post '/pipelines' do
        version = $events.version

        branch = params[:pipeline_branch]

        if @project.has_pipeline_for_branch?(branch)
          pipeline = @project.find_pipeline_by_branch(branch)
          flash "Branch <code>#{branch}</code> has already been assigned to the #{pipeline} pipeline"
          redirect pipelines_path(@project)
        end

        id = SecureRandom.uuid

        $events.record(:pipeline_added,
          if_version_equals: version,
          id: id,
          name: params[:pipeline_name],
          branch: params[:pipeline_branch],
          project_id: @project.id
        )

        @pipeline = @project.find_pipeline(id)

        redirect pipeline_path(@pipeline)
      end
    end
  end
end
