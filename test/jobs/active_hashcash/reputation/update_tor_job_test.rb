require "test_helper"

class ActiveHashcash::Reputation::UpdateTorJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateTorJob, "1.2.3.4\n5.6.7.8\n") do
      ActiveHashcash::Reputation::UpdateTorJob.perform_now
    end
    assert_operator(ActiveHashcash::Reputation::IPv4.where(tor_score: 1).count, :>, 0)
  end
end
