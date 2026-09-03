require "test_helper"

class ActiveHashcash::Reputation::UpdateAnonymousJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAnonymousJob, "1.2.3.4\n10.0.0.0/24\n") do
      ActiveHashcash::Reputation::UpdateAnonymousJob.perform_now
    end
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("10.0.0.50")[:anonymous])
  end
end
