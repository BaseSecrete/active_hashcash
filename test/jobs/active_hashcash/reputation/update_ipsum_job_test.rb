require "test_helper"

class ActiveHashcash::Reputation::UpdateIPSumJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_memory_cache do
      Rails.cache.write(ActiveHashcash::Reputation::UpdateIPSumJob.enqueued_key, true)
      with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateIPSumJob, "1.2.3.4 5\n") do
        ActiveHashcash::Reputation::UpdateIPSumJob.perform_now
      end
      assert_operator(ActiveHashcash::Reputation::IPv4.where("ipsum_score > 0").count, :>, 0)
      assert_kind_of(Time, Rails.cache.read(ActiveHashcash::Reputation::UpdateIPSumJob.refreshed_at_key))
      assert_nil(Rails.cache.read(ActiveHashcash::Reputation::UpdateIPSumJob.enqueued_key))
    end
  end

  def test_perform_later_once
    with_memory_cache do
      assert_enqueued_jobs(1, only: ActiveHashcash::Reputation::UpdateIPSumJob) do
        2.times { ActiveHashcash::Reputation::UpdateIPSumJob.perform_later_once }
      end
      assert(Rails.cache.read(ActiveHashcash::Reputation::UpdateIPSumJob.enqueued_key))
    end
  end
end
