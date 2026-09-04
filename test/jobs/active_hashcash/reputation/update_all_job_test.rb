require "test_helper"

class ActiveHashcash::Reputation::UpdateAllJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
      ActiveHashcash::Reputation::UpdateAbuseJob
      ActiveHashcash::Reputation::UpdateAnonymousJob
      ActiveHashcash::Reputation::UpdateAttackJob
    jobs = ActiveHashcash::Reputation::UpdateJob.subclasses + [ActiveHashcash::Reputation::CleanupJob]
    with_stubbed_job_fetch(jobs.first, "1.2.3.4\n") do
      assert_enqueued_with(job: ActiveHashcash::Reputation::UpdateAllJob, args: [jobs[1..]]) do
        ActiveHashcash::Reputation::UpdateAllJob.perform_now
      end
    end
  end

  def test_perform_last_job
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAttackJob, "1.2.3.4\n") do
      assert_no_enqueued_jobs do
        ActiveHashcash::Reputation::UpdateAllJob.perform_now([ActiveHashcash::Reputation::UpdateAttackJob])
      end
    end
    assert_equal(4, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:attack])
  end
end
