require "test_helper"

class ActiveHashcash::Reputation::UpdateAnonymousScoreJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAnonymousScoreJob, "1.2.3.4\n203.0.113.0/24\n") do
      ActiveHashcash::Reputation::UpdateAnonymousScoreJob.perform_now
    end
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("203.0.113.50")[:anonymous])
  end

  def test_perform_skips_overly_broad_nets
    assert_difference("ActiveHashcash::Reputation::IPv4.count") do
      with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAnonymousScoreJob, "1.0.0.0/15\n2.0.0.0/16") do
        ActiveHashcash::Reputation::UpdateAnonymousScoreJob.perform_now
      end
    end
    assert_equal(0, ActiveHashcash::Reputation::IPv4.scores("1.0.0.0")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("2.0.0.0")[:anonymous])
  end
end
