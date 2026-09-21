require "test_helper"
require "ipaddr"

class ActiveHashcash::Reputation::IPv4RangeTest < ActiveSupport::TestCase
  def test_scores
    scores = {abuse: 0, anonymous: 0, attack: 0}
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("9.255.255.255"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("10.0.0.0"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("10.0.0.1"))
    assert_equal(scores.merge(abuse: 1), ActiveHashcash::Reputation::IPv4Range.scores("10.6.0.0"))
    assert_equal(scores.merge(abuse: 1), ActiveHashcash::Reputation::IPv4Range.scores("10.6.6.6"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("10.255.255.255"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("11.0.0.0"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Range.scores("invalid"))
  end

  def test_reset_score
    ip = IPAddr.new("203.0.113.0/24")
    ActiveHashcash::Reputation::IPv4Range.reset_score(:anonymous, [[ip, 1]])
    assert_equal(1, ActiveHashcash::Reputation::IPv4Range.scores("203.0.113.50")[:anonymous])

    ActiveHashcash::Reputation::IPv4Range.reset_score(:anonymous, [[IPAddr.new("198.51.100.0/24"), 1]])
    assert_equal(0, ActiveHashcash::Reputation::IPv4Range.scores("203.0.113.50")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4Range.scores("198.51.100.1")[:anonymous])
  end

  def test_delete_zero_scores
    assert_no_difference("ActiveHashcash::Reputation::IPv4Range.count") do
      ActiveHashcash::Reputation::IPv4Range.delete_zero_scores
    end

    ActiveHashcash::Reputation::IPv4Range.first.update!(abuse_score: 0, anonymous_score: 0, attack_score: 0)
    assert_difference("ActiveHashcash::Reputation::IPv4Range.count", -1) do
      ActiveHashcash::Reputation::IPv4Range.delete_zero_scores
    end
  end
end
