require 'test_helper'

class InfrastructureFlowsTest < ActionDispatch::IntegrationTest
  def setup; Fog.mock!; end
  def teardown; Fog.unmock!; end
  
  test "should show the infrastructure dashboard" do
    get '/servers'
    assert_response :success
    assert assigns(:servers)
  end
end
