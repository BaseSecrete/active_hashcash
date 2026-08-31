require "test_helper"

class ActiveHashcash::Reputation::UpdateSpamhausJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_memory_cache do
      Rails.cache.write(ActiveHashcash::Reputation::UpdateSpamhausJob.enqueued_key, true)
      with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateSpamhausJob, "10.0.0.0/8 ; DROP\n") do
        ActiveHashcash::Reputation::UpdateSpamhausJob.perform_now
      end
      assert_operator(ActiveHashcash::Reputation::IPv4.where(spamhaus_score: 1).count, :>, 0)
      assert_kind_of(Time, Rails.cache.read(ActiveHashcash::Reputation::UpdateSpamhausJob.refreshed_at_key))
      assert_nil(Rails.cache.read(ActiveHashcash::Reputation::UpdateSpamhausJob.enqueued_key))
    end
  end

  def test_perform_later_once
    with_memory_cache do
      assert_enqueued_jobs(1, only: ActiveHashcash::Reputation::UpdateSpamhausJob) do
        2.times { ActiveHashcash::Reputation::UpdateSpamhausJob.perform_later_once }
      end
      assert(Rails.cache.read(ActiveHashcash::Reputation::UpdateSpamhausJob.enqueued_key))
    end
  end
end
