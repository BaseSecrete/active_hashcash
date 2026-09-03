require "test_helper"

class ActiveHashcashTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class SampleController < ApplicationController
    include ActiveHashcash

    def hashcash_ip_address
      "127.0.0.1"
    end
  end

  def test_hashcash_bits
    bits = ActiveHashcash.bits
    controller = SampleController.new
    assert_equal(ActiveHashcash.bits, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:001").update!(ip_address: "127.0.0.1")
    assert_equal((bits + 1 * 0.5).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:002").update!(ip_address: "127.0.0.1")
    assert_equal((bits + 2 * 0.5).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:003").update!(ip_address: "127.0.0.1")
    assert_equal((bits + 3 * 0.5).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:004").update!(ip_address: "127.0.0.1")
    assert_equal((bits + 4 * 0.5).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:005").update!(ip_address: "127.0.0.1", created_at: 2.hours.ago)
    assert_equal((bits + 4 * 0.5 + 1 * 0.25).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:006").update!(ip_address: "127.0.0.1", created_at: 2.hours.ago)
    assert_equal((bits + 4 * 0.5 + 2 * 0.25).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:007").update!(ip_address: "127.0.0.1", created_at: 2.hours.ago)
    assert_equal((bits + 4 * 0.5 + 3 * 0.25).floor, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:008").update!(ip_address: "127.0.0.1", created_at: 2.hours.ago)
    assert_equal((bits + 4 * 0.5 + 4 * 0.25).floor, controller.hashcash_bits)
  end

  def test_throttle_rules_are_sorted
    old_rules = ActiveHashcash.throttle_rules
    ActiveHashcash.throttle_rules = [
      {period: 24.hours, rate: 0.25},
      {period: 5.minutes, rate: 1.0},
      {period: 1.hour, rate: 0.5}
    ]

    assert_equal([5.minutes, 1.hour, 24.hours], ActiveHashcash.throttle_rules.map { |rule| rule[:period] })
    assert_equal([1.0, 0.5, 0.25], ActiveHashcash.throttle_rules.map { |rule| rule[:rate] })
  ensure
    ActiveHashcash.throttle_rules = old_rules
  end

  def test_throttle_rules_reject_negative_rate
    old_rules = ActiveHashcash.throttle_rules

    assert_raises(ArgumentError) do
      ActiveHashcash.throttle_rules = [{period: 1.hour, rate: -0.5}]
    end
    assert_equal(old_rules, ActiveHashcash.throttle_rules)
  ensure
    ActiveHashcash.throttle_rules = old_rules
  end

  def test_throttle_rules_reject_nil_period
    old_rules = ActiveHashcash.throttle_rules

    assert_raises(ArgumentError) do
      ActiveHashcash.throttle_rules = [{period: nil, rate: 0.5}]
    end
    assert_equal(old_rules, ActiveHashcash.throttle_rules)
  ensure
    ActiveHashcash.throttle_rules = old_rules
  end

  def test_hashcash_reputation_penalty
    controller = SampleController.new
    assert_equal(0, controller.hashcash_reputation_penalty)
    controller.stub(:hashcash_ip_address, "10.6.6.6") do
      assert_equal(4*1 + 4*1 + 1*3 + 4*0 + 4*0 + 4*0, controller.hashcash_reputation_penalty)
    end
  end

end
