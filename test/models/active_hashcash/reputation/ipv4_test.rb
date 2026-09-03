require "test_helper"

class ActiveHashcash::Reputation::IPv4Test < ActiveSupport::TestCase
  def test_scores
    zeros = {tor: 0, spamhaus: 0, ipsum: 0, abuse: 0, anonymous: 0, attack: 0}
    assert_equal(zeros, ActiveHashcash::Reputation::IPv4.scores("9.255.255.255"))
    assert_equal(zeros.merge(spamhaus: 1), ActiveHashcash::Reputation::IPv4.scores("10.0.0.0"))
    assert_equal(zeros.merge(spamhaus: 1), ActiveHashcash::Reputation::IPv4.scores("10.0.0.1"))
    assert_equal(zeros.merge(spamhaus: 1, ipsum: 1), ActiveHashcash::Reputation::IPv4.scores("10.6.0.0"))
    assert_equal(zeros.merge(tor: 1, spamhaus: 1, ipsum: 3), ActiveHashcash::Reputation::IPv4.scores("10.6.6.6"))
    assert_equal(zeros.merge(spamhaus: 1), ActiveHashcash::Reputation::IPv4.scores("10.255.255.255"))
    assert_equal(zeros, ActiveHashcash::Reputation::IPv4.scores("11.0.0.0"))
    assert_equal(zeros, ActiveHashcash::Reputation::IPv4.scores("invalid"))
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

  def test_net_to_range
    ip_start, ip_end = ActiveHashcash::Reputation::IPv4.net_to_range("1.2.3.4")
    assert_equal(ip_start, ip_end)

    cidr_start, cidr_end = ActiveHashcash::Reputation::IPv4.net_to_range("10.0.0.0/8")
    assert_equal(ActiveHashcash::Reputation::IPv4.cidr_to_range("10.0.0.0/8"), [cidr_start, cidr_end])
  end
end
