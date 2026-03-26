require "test_helper"

class ActiveHashcashTest < ActiveSupport::TestCase
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

end
