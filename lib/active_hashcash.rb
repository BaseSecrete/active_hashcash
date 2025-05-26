require "active_hashcash/version"
require "active_hashcash/engine"
require "active_hashcash/concern"

# ActiveHashcash protects Rails applications against bots and brute force attacks without annoying humans.
# See the rdoc-ref:README.md for more explanations about Hashcash.
#
# Include this module into your Rails controller.
#
#   class SessionController < ApplicationController
#     include ActiveHashcash::Concern
#
#     before_action :check_hashcash, only: :create
#   end
#
# Your are welcome to override most of the methods to customize to your needs.
# For example, if your app runs behind a loab balancer you should probably override #hashcash_ip_address.
#
module ActiveHashcash
  mattr_accessor :resource, instance_accessor: false

  # This is base complexity.
  # Consider lowering it to not exclude people with old and slow devices.
  mattr_accessor :bits, instance_accessor: false, default: 16

  mattr_accessor :date_format, instance_accessor: false, default: "%y%m%d"

  mattr_accessor :base_controller_class, default: "ActionController::Base"

  def self.included(klass)
    raise "Since version 0.5.0, you must include ActiveHashcash::Concern in your controller instead of ActiveHashcash."
  end
end
