require "test_helper"

class ActiveHashcash::ReputationTest < ActiveSupport::TestCase
  def test_scores
    scores = {abuse: 0, anonymous: 0, attack: 0}
    assert_equal(scores, ActiveHashcash::Reputation.scores("9.255.255.255"))
    assert_equal(scores, ActiveHashcash::Reputation.scores("10.0.0.0"))
    assert_equal(scores.merge(abuse: 1), ActiveHashcash::Reputation.scores("10.6.0.0"))
    assert_equal(scores.merge(abuse: 2, attack: 4), ActiveHashcash::Reputation.scores("10.6.6.6"))
    assert_equal(scores, ActiveHashcash::Reputation.scores("11.0.0.0"))
    assert_equal(scores, ActiveHashcash::Reputation.scores("invalid"))
  end
end
