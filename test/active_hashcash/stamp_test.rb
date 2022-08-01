require "test_helper"

class ActiveHashcash::StampTest < Minitest::Test
  def test_valid?
    assert(true)
    assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").valid?)
    refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").valid?)
  end
end
