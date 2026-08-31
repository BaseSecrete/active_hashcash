require "test_helper"

class ActiveHashcash::Reputation::IPv4Test < ActiveSupport::TestCase
  setup do
    ActiveHashcash::Reputation::IPv4.delete_all
  end

  def test_lookup_for_single_ip
    range_start, range_end = ActiveHashcash::Reputation::IPv4.ip_to_range("1.2.3.4")
    ActiveHashcash::Reputation::IPv4.create!(
      range_start: range_start,
      range_end: range_end,
      tor_score: 1,
      spamhaus_score: 0,
      ipsum_score: 3
    )

    scores = ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")
    assert_equal(1, scores[:tor])
    assert_equal(0, scores[:spamhaus])
    assert_equal(3, scores[:ipsum])
  end

  def test_lookup_for_cidr_range
    range_start, range_end = ActiveHashcash::Reputation::IPv4.cidr_to_range("10.0.0.0/8")
    ActiveHashcash::Reputation::IPv4.create!(
      range_start: range_start,
      range_end: range_end,
      tor_score: 0,
      spamhaus_score: 1,
      ipsum_score: 0
    )

    scores = ActiveHashcash::Reputation::IPv4.scores("10.1.2.3")
    assert_equal(0, scores[:tor])
    assert_equal(1, scores[:spamhaus])
    assert_equal(0, scores[:ipsum])
  end

  def test_bulk_upsert_scores
    now = Time.current
    range_start, range_end = ActiveHashcash::Reputation::IPv4.ip_to_range("1.2.3.4")
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[range_start, range_end, 5]], score: :ipsum_score, now: now)
    ActiveHashcash::Reputation::IPv4.bulk_upsert_scores([[range_start, range_end, 1]], score: :tor_score, now: now)

    scores = ActiveHashcash::Reputation::IPv4.scores("1.2.3.4")
    assert_equal(1, scores[:tor])
    assert_equal(5, scores[:ipsum])
  end
end
