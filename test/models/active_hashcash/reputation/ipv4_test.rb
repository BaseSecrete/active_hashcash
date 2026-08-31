require "test_helper"

class ActiveHashcash::Reputation::IPv4Test < ActiveSupport::TestCase
  def test_scores
    assert_equal({tor: 0, spamhaus: 0, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("9.255.255.255"))
    assert_equal({tor: 0, spamhaus: 1, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("10.0.0.0"))
    assert_equal({tor: 0, spamhaus: 1, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("10.0.0.1"))
    assert_equal({tor: 0, spamhaus: 1, ipsum: 1}, ActiveHashcash::Reputation::IPv4.scores("10.6.0.0"))
    assert_equal({tor: 1, spamhaus: 1, ipsum: 3}, ActiveHashcash::Reputation::IPv4.scores("10.6.6.6"))
    assert_equal({tor: 0, spamhaus: 1, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("10.255.255.255"))
    assert_equal({tor: 0, spamhaus: 0, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("11.0.0.0"))
    assert_equal({tor: 0, spamhaus: 0, ipsum: 0}, ActiveHashcash::Reputation::IPv4.scores("invalid"))
  end

  def test_bulk_upsert_scores
    timestamp = Time.current
    range_start, range_end = ActiveHashcash::Reputation::IPv4.ip_to_range("1.2.3.4")
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[range_start, range_end, 5]], :ipsum_score, timestamp)
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[range_start, range_end, 1]], :tor_score, timestamp)

    scores = ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")
    assert_equal(1, scores[:tor])
    assert_equal(5, scores[:ipsum])
  end
end
