require "test_helper"

class ActiveHashcash::Reputation::UpdateAllScoresJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    jobs = [
      ActiveHashcash::Reputation::UpdateAnonymousScoreJob,
      ActiveHashcash::Reputation::UpdateAttackScoreJob,
      ActiveHashcash::Reputation::CleanupJob
    ]
    with_stubbed_job_fetch(jobs.first, "1.2.3.4\n") do
      assert_enqueued_with(job: ActiveHashcash::Reputation::UpdateAllScoresJob, args: [jobs]) do
        ActiveHashcash::Reputation::UpdateAllScoresJob.perform_now
      end
    end
  end

  def test_perform_last_job
    with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateAttackScoreJob, "1.2.3.4\n") do
      assert_no_enqueued_jobs do
        ActiveHashcash::Reputation::UpdateAllScoresJob.perform_now([ActiveHashcash::Reputation::UpdateAttackScoreJob])
      end
    end
    assert_equal(4, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:attack])
  end
end
