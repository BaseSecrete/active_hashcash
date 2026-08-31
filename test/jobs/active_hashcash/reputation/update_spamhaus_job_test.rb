require "test_helper"

class ActiveHashcash::Reputation::UpdateSpamhausJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateSpamhausJob, "10.0.0.0/8 ; DROP\n") do
      ActiveHashcash::Reputation::UpdateSpamhausJob.perform_now
    end
    assert_operator(ActiveHashcash::Reputation::IPv4.where(spamhaus_score: 1).count, :>, 0)
  end
end
