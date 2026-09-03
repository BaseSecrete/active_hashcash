require "test_helper"

class ActiveHashcash::Reputation::UpdateAttackJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAttackJob, "1.2.3.4\n10.0.0.0/8\n") do
      ActiveHashcash::Reputation::UpdateAttackJob.perform_now
    end
    assert_equal(4, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:attack])
    assert_equal(4, ActiveHashcash::Reputation::IPv4.scores("10.1.2.3")[:attack])
  end

  def test_perform_keeps_higher_score
    job = ActiveHashcash::Reputation::UpdateAttackJob.new
    bodies = {
      "https://iplists.firehol.org/files/firehol_level1.netset" => "1.2.3.4\n",
      "https://iplists.firehol.org/files/firehol_level2.netset" => "",
      "https://iplists.firehol.org/files/firehol_level3.netset" => "5.6.7.8\n",
      "https://iplists.firehol.org/files/firehol_level4.netset" => "1.2.3.4\n9.9.9.9\n"
    }
    job.define_singleton_method(:fetch) { |url = nil| bodies.fetch(url) }
    ActiveHashcash::Reputation::UpdateAttackJob.stub(:new, job) do
      ActiveHashcash::Reputation::UpdateAttackJob.perform_now
    end
    assert_equal(4, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:attack])
    assert_equal(2, ActiveHashcash::Reputation::IPv4.scores("5.6.7.8")[:attack])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("9.9.9.9")[:attack])
  end
end
