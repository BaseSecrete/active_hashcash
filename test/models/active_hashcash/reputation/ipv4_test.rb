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

  def test_bulk_upsert_scores
    ip = IPAddr.new("1.2.3.4")
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[ip, 2]], :abuse_score)
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[ip, 4]], :attack_score)

    scores = ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")
    assert_equal(2, scores[:abuse])
    assert_equal(4, scores[:attack])
  end
end
