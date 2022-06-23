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

class ActiveHashcashTest < Minitest::Test
  def test_stamp
    assert(true)
    assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").valid?)
    refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").valid?)
  end

  class SampleController < ActionController::Base
    include ActiveHashcash

    def params
      {hashcash: "1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh"}
    end
  end

  def test_check_hashcash_when_spent_twice
    controller = SampleController.new
    controller.hashcash_redis.del("active_hashcash_stamps")
    controller.check_hashcash
    assert_raises(ActionController::InvalidAuthenticityToken) { controller.check_hashcash }
  end
end
