require 'test_helper'

class DeployComponentJobTest < ActiveJob::TestCase
  def setup; Fog.mock!; end
  def teardown; Fog.unmock!; end
  
  test "should do what it says on the box" do
    component = Component.find(:leonore)
    perform_enqueued_jobs do
      DeployComponentJob.perform_later(component, action: 'deploy')
    end
    assert_performed_jobs 1
  end
end
