require 'test_helper'

class ComponentsControllerTest < ActionController::TestCase
  def setup; Fog.mock!; end
  def teardown; Fog.unmock!; end
  
  test "should get deploy" do
    get :deploy, component_id: 'leonore'
    assert_response :redirect
  end

  test "should get undeploy" do
    get :undeploy, component_id: 'leonore'
    assert_response :redirect
  end
end
