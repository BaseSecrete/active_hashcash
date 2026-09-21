require "test_helper"

class ActiveHashcash::Reputation::UpdateAttackScoreJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAttackScoreJob, "1.2.3.4\n203.0.113.0/24\n") do
      ActiveHashcash::Reputation::UpdateAttackScoreJob.perform_now
    end
    assert_equal(4, ActiveHashcash::Reputation.scores("1.2.3.4")[:attack])
    assert_equal(4, ActiveHashcash::Reputation.scores("203.0.113.50")[:attack])
  end

  def test_perform_keeps_higher_score
    job = ActiveHashcash::Reputation::UpdateAttackScoreJob.new
    bodies = {
      "https://iplists.firehol.org/files/firehol_level1.netset" => "1.2.3.4\n",
      "https://iplists.firehol.org/files/firehol_level2.netset" => "",
      "https://iplists.firehol.org/files/firehol_level3.netset" => "5.6.7.8\n",
      "https://iplists.firehol.org/files/firehol_level4.netset" => "1.2.3.4\n9.9.9.9\n"
    }
    job.define_singleton_method(:fetch) { |url = nil| bodies.fetch(url) }
    ActiveHashcash::Reputation::UpdateAttackScoreJob.stub(:new, job) do
      ActiveHashcash::Reputation::UpdateAttackScoreJob.perform_now
    end
    assert_equal(4, ActiveHashcash::Reputation.scores("1.2.3.4")[:attack])
    assert_equal(2, ActiveHashcash::Reputation.scores("5.6.7.8")[:attack])
    assert_equal(1, ActiveHashcash::Reputation.scores("9.9.9.9")[:attack])
  end
end
