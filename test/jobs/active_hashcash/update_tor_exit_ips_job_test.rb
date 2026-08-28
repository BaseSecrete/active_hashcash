require "test_helper"

class ActiveHashcash::UpdateTorExitIpsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    with_memory_cache do
      Rails.cache.write(ActiveHashcash::UpdateTorExitIpsJob::ENQUEUED_KEY, true)
      ActiveHashcash::UpdateTorExitIpsJob.perform_now
      cached = Rails.cache.read(ActiveHashcash::UpdateTorExitIpsJob::CACHE_KEY)
      assert_not_nil(cached)
      assert_kind_of(Time, cached[:updated_at])
      assert_operator(cached[:ips].size, :>, 0)
      assert_equal(cached[:ips].sort, cached[:ips])
      assert(IPAddr.new(cached[:ips].first))
      assert_nil(Rails.cache.read(ActiveHashcash::UpdateTorExitIpsJob::ENQUEUED_KEY))
    end
  end

  def test_perform_later_once
    with_memory_cache do
      assert_enqueued_jobs(1, only: ActiveHashcash::UpdateTorExitIpsJob) do
        2.times { ActiveHashcash::UpdateTorExitIpsJob.perform_later_once }
      end
      assert(Rails.cache.read(ActiveHashcash::UpdateTorExitIpsJob::ENQUEUED_KEY))
    end
  end
end
