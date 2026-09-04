require "test_helper"
require "ipaddr"

class ActiveHashcash::Reputation::IPv4AddressTest < ActiveSupport::TestCase
  def test_scores
    scores = {abuse: 0, anonymous: 0, attack: 0}
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Address.scores("10.6.0.0"))
    assert_equal(scores.merge(abuse: 2, attack: 4), ActiveHashcash::Reputation::IPv4Address.scores("10.6.6.6"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4Address.scores("invalid"))
  end

  def test_reset_score
    ip = IPAddr.new("1.2.3.4")
    ActiveHashcash::Reputation::IPv4Address.reset_score(:anonymous, [[ip, 1]])
    assert_equal(1, ActiveHashcash::Reputation::IPv4Address.scores("1.2.3.4")[:anonymous])

    ActiveHashcash::Reputation::IPv4Address.reset_score(:anonymous, [[IPAddr.new("5.6.7.8"), 1]])
    assert_equal(0, ActiveHashcash::Reputation::IPv4Address.scores("1.2.3.4")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4Address.scores("5.6.7.8")[:anonymous])
  end

  def test_delete_zero_scores
    assert_no_difference("ActiveHashcash::Reputation::IPv4Address.count") do
      ActiveHashcash::Reputation::IPv4Address.delete_zero_scores
    end

    ActiveHashcash::Reputation::IPv4Address.first.update!(abuse_score: 0, anonymous_score: 0, attack_score: 0)
    assert_difference("ActiveHashcash::Reputation::IPv4Address.count", -1) do
      ActiveHashcash::Reputation::IPv4Address.delete_zero_scores
    end
  end
end
