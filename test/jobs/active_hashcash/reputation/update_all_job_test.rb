require "test_helper"

class ActiveHashcash::Reputation::UpdateAllJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    assert_enqueued_jobs(3) do
      ActiveHashcash::Reputation::UpdateAllJob.perform_now
    end
  end
end
