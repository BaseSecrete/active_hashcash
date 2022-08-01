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
