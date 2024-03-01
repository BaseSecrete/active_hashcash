require "test_helper"

class ActiveHashcashTest < ActiveSupport::TestCase

  class SampleController < ApplicationController
    include ActiveHashcash

    def hashcash_ip_address
      "127.0.0.1"
    end
  end

  def test_hashcash_bits
    controller = SampleController.new
    assert_equal(ActiveHashcash.bits, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:001").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:002").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 1, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:003").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 1, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:004").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 2, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:005").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 2, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:006").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 2, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:007").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 2, controller.hashcash_bits)

    ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:008").update!(ip_address: "127.0.0.1")
    assert_equal(ActiveHashcash.bits + 3, controller.hashcash_bits)
  end
end
