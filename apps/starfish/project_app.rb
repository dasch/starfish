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
        @pipeline = @project.pipelines.first
      end

      get '' do
        redirect @pipeline ? pipeline_path(@pipeline) : pipelines_path(@project)
      end

      get '/settings' do
        erb :project_settings
      end

      post '/settings' do
        if params[:name] != @project.name
          $events.record(:project_renamed, {
            id: @project.id,
            name: params[:name],
          })
        end

        flash "Project has been renamed"

        redirect project_path(@project)
      end

      get '/pipelines' do
        erb :list_pipelines
      end

      post '/pipelines' do
        branch = params[:pipeline_branch]

        if @project.has_pipeline_for_branch?(branch)
          pipeline = @project.find_pipeline_by_branch(branch)
          flash "Branch <code>#{branch}</code> has already been assigned to the #{pipeline} pipeline"
          redirect pipelines_path(@project)
        end

        id = SecureRandom.uuid

        $events.record(:pipeline_added, {
          id: id,
          name: params[:pipeline_name],
          branch: params[:pipeline_branch],
          project_id: @project.id,
          author: current_user,
        })

        @pipeline = @project.find_pipeline(id)

        redirect pipeline_path(@pipeline)
      end
    end
  end
end
