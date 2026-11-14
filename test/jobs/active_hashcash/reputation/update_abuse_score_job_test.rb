require "test_helper"

class ActiveHashcash::Reputation::UpdateAbuseScoreJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAbuseScoreJob, "1.2.3.4\n203.0.113.0/24\n") do
      ActiveHashcash::Reputation::UpdateAbuseScoreJob.perform_now
    end
    assert_equal(2, ActiveHashcash::Reputation.scores("1.2.3.4")[:abuse])
    assert_equal(2, ActiveHashcash::Reputation.scores("203.0.113.50")[:abuse])
  end

  def test_perform_keeps_higher_score
    job = ActiveHashcash::Reputation::UpdateAbuseScoreJob.new
    bodies = {
      "https://iplists.firehol.org/files/firehol_abusers_1d.netset" => "1.2.3.4\n",
      "https://netapi.com/api2/?method=compromised&dataset_type=ip" => "# NetAPI.com - currently compromised IPs (2026-11-13).\n9.9.9.9\n",
      "https://iplists.firehol.org/files/firehol_abusers_30d.netset" => "1.2.3.4\n5.6.7.8\n9.9.9.9\n"
    }
    job.define_singleton_method(:fetch) { |url = nil| bodies.fetch(url) }
    ActiveHashcash::Reputation::UpdateAbuseScoreJob.stub(:new, job) do
      ActiveHashcash::Reputation::UpdateAbuseScoreJob.perform_now
    end
    assert_equal(2, ActiveHashcash::Reputation.scores("1.2.3.4")[:abuse])
    assert_equal(1, ActiveHashcash::Reputation.scores("5.6.7.8")[:abuse])
    assert_equal(2, ActiveHashcash::Reputation.scores("9.9.9.9")[:abuse])
  end
end
