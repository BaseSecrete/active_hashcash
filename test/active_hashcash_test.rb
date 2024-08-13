require "test_helper"
require 'minitest/mock'

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

  def test_hashcash_hidden_field_tag
    controller = SampleController.new
    controller.request = Minitest::Mock.new
    controller.request.expect :host, 'foo.test'

    options = { resource: 'foo.test', bits: ActiveHashcash.bits, waiting_message: I18n.t("active_hashcash.waiting_label") }
    options = ERB::Util.html_escape(options.to_json)
    field = "<input type=\"hidden\" name=\"hashcash\" id=\"hashcash\" value=\"\" data-hashcash=\"#{options}\" autocomplete=\"off\" />"
    assert_equal(controller.hashcash_hidden_field_tag, field)
  end
end
