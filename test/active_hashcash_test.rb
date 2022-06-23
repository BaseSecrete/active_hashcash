path = File.expand_path("#{File.dirname(__FILE__)}/../lib")
$LOAD_PATH.unshift(path)

# Stubs Rails::Engine.config.assets.paths
require "rails"
module ActiveHashcash
  class Engine < ::Rails::Engine
    config.assets = Rails::Railtie::Configuration.new
    config.assets.paths = []
  end
end

require "active_hashcash"
require "minitest/autorun"

class ActiveHashcashTest < Minitest::Test
  def test_stamp
    assert(true)
    assert(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh").valid?)
    refute(ActiveHashcash::Stamp.parse("1:20:220623:test::MPWRGuN3itbd1NiQ:00000000000003krh_").valid?)
  end
end
