require 'test_helper'

class ComponentTest < ActiveSupport::TestCase
  def setup; Fog.mock!; end
  def teardown; Fog.unmock!; end

  test "should return available components" do
    assert_not_empty Component.all
    assert Component.all.any? { |c| c.id == 'leonore' }
  end

  test "should allow to search by id" do
    assert_equal Component.find('leonore'), Component.find(:leonore)
    component = Component.find(:leonore)
    assert_not_empty component.steps
  end

  test "should execute deployment" do
    component = Component.find(:leonore)
    component.deploy
    puts component.deployment_status.inspect
  end
  
  test "should return deployment steps up to a given stage" do
    component = Component.find(:leonore)
    assert_equal [ 'start_balancer', 'start_nodes' ], component.deployment_steps_upto('start_nodes')
  end
end
