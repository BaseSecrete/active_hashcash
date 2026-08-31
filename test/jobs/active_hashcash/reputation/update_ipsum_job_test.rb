require "test_helper"

class ActiveHashcash::Reputation::UpdateIPSumJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateIPSumJob, "1.2.3.4 5\n") do
      ActiveHashcash::Reputation::UpdateIPSumJob.perform_now
    end
    assert_operator(ActiveHashcash::Reputation::IPv4.where("ipsum_score > 0").count, :>, 0)
  end
end
