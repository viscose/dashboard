class ComponentsController < ApplicationController
  before_filter :load_component
  
  def deploy
    DeployComponentJob.perform_later(@component, action: 'deploy')
    redirect_to servers_path
  end

  def undeploy
    DeployComponentJob.perform_later(@component, action: 'undeploy')
    redirect_to servers_path
  end
  
  def execute_steps
    DeployComponentJob.perform_later(@component, steps: params[:steps])
    redirect_to servers_path
  end
  
  private
  def load_component
    @component = Component.find(params[:component_id])
  end
end
