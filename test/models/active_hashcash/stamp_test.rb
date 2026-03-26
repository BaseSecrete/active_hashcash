require "test_helper"

module ActiveHashcash
  class StampTest < ActiveSupport::TestCase
    def test_parse_and_to_s
      refute(ActiveHashcash::Stamp.parse(nil))
      refute(ActiveHashcash::Stamp.parse(""))
      refute(ActiveHashcash::Stamp.parse("1:20:220623"))

      str = "1:20:220623:test:sha256:MPWRGuN3itbd1NiQ:42"
      parsed = ActiveHashcash::Stamp.parse(str)
      assert_equal(str, parsed.to_s)
      assert_equal("sha256", parsed.ext)
    end

    def test_authentic?
      assert(ActiveHashcash::Stamp.parse("1:8:260326:test:sha256:DijFBDmOOfmEMXjk:450").authentic?)
      refute(ActiveHashcash::Stamp.parse("1:8:260326:test:sha256:DijFBDmOOfmEMXjk:000").authentic?)
    end

    def test_authentic_sha1_backward_compatibility
      assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").authentic?)
      refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").authentic?)
    end

    def test_mint_sets_sha256_ext
      stamp = ActiveHashcash::Stamp.mint("resource", bits: 2)
      assert_equal("sha256", stamp.ext)
      assert(stamp.authentic?)
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
