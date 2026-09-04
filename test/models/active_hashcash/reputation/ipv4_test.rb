require "test_helper"
require "ipaddr"

class ActiveHashcash::Reputation::IPv4Test < ActiveSupport::TestCase
  def test_scores
    scores = {abuse: 0, anonymous: 0, attack: 0}
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("9.255.255.255"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("10.0.0.0"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("10.0.0.1"))
    assert_equal(scores.merge(abuse: 1), ActiveHashcash::Reputation::IPv4.scores("10.6.0.0"))
    assert_equal(scores.merge(abuse: 3, attack: 4), ActiveHashcash::Reputation::IPv4.scores("10.6.6.6"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("10.255.255.255"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("11.0.0.0"))
    assert_equal(scores, ActiveHashcash::Reputation::IPv4.scores("invalid"))
  end

  def test_reset_score
    ip = IPAddr.new("1.2.3.4")
    ActiveHashcash::Reputation::IPv4.reset_score(:anonymous_score, [[ip, 1]])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:anonymous])

    ActiveHashcash::Reputation::IPv4.reset_score(:anonymous_score, [[IPAddr.new("5.6.7.8"), 1]])
    assert_equal(0, ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")[:anonymous])
    assert_equal(1, ActiveHashcash::Reputation::IPv4.scores("5.6.7.8")[:anonymous])
  end
end
