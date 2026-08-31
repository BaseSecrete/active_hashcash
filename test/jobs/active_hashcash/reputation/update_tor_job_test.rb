require "test_helper"

class ActiveHashcash::Reputation::UpdateTorJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_memory_cache do
      Rails.cache.write(ActiveHashcash::Reputation::UpdateTorJob.enqueued_key, true)
      with_stubbed_job_fetch(ActiveHashcash::Reputation::UpdateTorJob, "1.2.3.4\n5.6.7.8\n") do
        ActiveHashcash::Reputation::UpdateTorJob.perform_now
      end
      assert_operator(ActiveHashcash::Reputation::IPv4.where(tor_score: 1).count, :>, 0)
      assert_kind_of(Time, Rails.cache.read(ActiveHashcash::Reputation::UpdateTorJob.refreshed_at_key))
      assert_nil(Rails.cache.read(ActiveHashcash::Reputation::UpdateTorJob.enqueued_key))
    end
  end

  def test_perform_later_once
    with_memory_cache do
      assert_enqueued_jobs(1, only: ActiveHashcash::Reputation::UpdateTorJob) do
        2.times { ActiveHashcash::Reputation::UpdateTorJob.perform_later_once }
      end
      assert(Rails.cache.read(ActiveHashcash::Reputation::UpdateTorJob.enqueued_key))
    end
  end
end
