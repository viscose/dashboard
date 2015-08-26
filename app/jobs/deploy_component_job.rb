class DeployComponentJob < ActiveJob::Base
  queue_as :default

  def perform(component, steps: nil, action: nil)
    raise 'Specify either steps or action to deploy!' if steps.nil? && action.nil?
    Component.logger ||= logger
    case action.to_s
    when 'deploy', 'undeploy'
      component.send(action)
    else
      component.deploy(step_names: steps)
    end
  end
end
