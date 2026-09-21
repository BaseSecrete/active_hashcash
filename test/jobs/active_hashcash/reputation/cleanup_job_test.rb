require "test_helper"

class ActiveHashcash::Reputation::CleanupJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    assert_no_difference(["ActiveHashcash::Reputation::IPv4Address.count", "ActiveHashcash::Reputation::IPv4Range.count"]) do
      ActiveHashcash::Reputation::CleanupJob.perform_now
    end

    ActiveHashcash::Reputation::IPv4Address.first.update!(abuse_score: 0, anonymous_score: 0, attack_score: 0)
    ActiveHashcash::Reputation::IPv4Range.first.update!(abuse_score: 0, anonymous_score: 0, attack_score: 0)
    assert_difference("ActiveHashcash::Reputation::IPv4Address.count", -1) do
      assert_difference("ActiveHashcash::Reputation::IPv4Range.count", -1) do
        ActiveHashcash::Reputation::CleanupJob.perform_now
      end
    end
  end
end
