require "test_helper"

module ActiveHashcash
  class StampTest < ActiveSupport::TestCase
    def test_parse_and_to_s
      refute(ActiveHashcash::Stamp.parse(nil))
      refute(ActiveHashcash::Stamp.parse(""))
      refute(ActiveHashcash::Stamp.parse("1:20:220623"))

      str = "1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh"
      assert_equal(str, ActiveHashcash::Stamp.parse(str).to_s)
    end

    def test_auhtentic?
      assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").authentic?)
      refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").authentic?)
    end

    def test_verify
      stamp = ActiveHashcash::Stamp.mint("resource", bits: 2, date: Date.yesterday)
      assert(stamp.verify("resource", 2, Date.yesterday))
      refute(stamp.verify("resource2", 2, Date.yesterday), "Different resource")
      refute(stamp.verify("resource", 2, Date.today), "Stamp too old")
      refute(stamp.verify("resource", 8, Date.yesterday), "Bits too low")

      stamp = ActiveHashcash::Stamp.mint("resource", bits: 2, date: Date.tomorrow)
      refute(stamp.verify("resource", 2, Date.today), "Cannot be in the future")
    end

    def test_spend
      refute(ActiveHashcash::Stamp.spend(nil, "resource", 2, Date.yesterday), "malformed")
      refute(ActiveHashcash::Stamp.spend("", "resource", 2, Date.yesterday), "malformed")
      refute(ActiveHashcash::Stamp.spend("1:20:220623", "resource", 2, Date.yesterday), "malformed")

      stamp = ActiveHashcash::Stamp.mint("resource", bits: 2, date: Date.yesterday)
      refute(ActiveHashcash::Stamp.spend(stamp.to_s, "resource2", 2, Date.yesterday), "wrong resource")
      assert(ActiveHashcash::Stamp.spend(stamp.to_s, "resource", 2, Date.yesterday), "first time spent")
      refute(ActiveHashcash::Stamp.spend(stamp.to_s, "resource", 2, Date.yesterday), "cannot be spent twice")
    end
  end
end
