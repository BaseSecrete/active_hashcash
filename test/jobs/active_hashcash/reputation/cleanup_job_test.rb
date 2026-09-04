require "test_helper"

class ActiveHashcash::Reputation::CleanupJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def test_perform
    assert_no_difference("ActiveHashcash::Reputation::IPv4.count") do
      ActiveHashcash::Reputation::CleanupJob.perform_now
    end

    ActiveHashcash::Reputation::IPv4.first.update!(abuse_score: 0, anonymous_score: 0, attack_score: 0)
    assert_difference("ActiveHashcash::Reputation::IPv4.count", -1) do
      ActiveHashcash::Reputation::CleanupJob.perform_now
    end
  end
end
