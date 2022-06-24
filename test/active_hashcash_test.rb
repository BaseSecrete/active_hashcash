path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

# Stubs Rails::Engine.config.assets.paths
require "action_controller"
require "active_support"
require "action_pack"
require "action_view"
require "rails"
module ActiveHashcash
  class Engine < ::Rails::Engine
    config.assets = Rails::Railtie::Configuration.new
    config.assets.paths = []
  end
end

require "redis"
require "active_hashcash"
require "minitest/autorun"

ActiveHashcash.bits = 2 # Speedup tests

class ActiveHashcashTest < Minitest::Test
  def test_stamp
    assert(true)
    assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").valid?)
    refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").valid?)
  end

  class SampleController < ActionController::Base
    include ActiveHashcash
    attr_accessor :params
  end

  def test_check_hashcash_when_spent_twice
    controller = SampleController.new
    controller.hashcash_redis.del("active_hashcash_stamps")
    controller.params = {hashcash: ActiveHashcash::Stamp.mint("test").to_s}

    controller.check_hashcash
    assert_raises(ActionController::InvalidAuthenticityToken) { controller.check_hashcash }
  end

  def test_check_hashcash_when_not_enough_bits
    controller = SampleController.new
    controller.hashcash_redis.del("active_hashcash_stamps")
    controller.params = {hashcash: ActiveHashcash::Stamp.mint("test", bits: 1).to_s}
    assert_raises(ActionController::InvalidAuthenticityToken) { controller.check_hashcash }
  end

  def test_check_hashcash_when_expired
    controller = SampleController.new
    controller.hashcash_redis.del("active_hashcash_stamps")
    p controller.params = {hashcash: ActiveHashcash::Stamp.mint("test", date: 2.days.ago.to_date).to_s}
    assert_raises(ActionController::InvalidAuthenticityToken) { controller.check_hashcash }
  end
end
