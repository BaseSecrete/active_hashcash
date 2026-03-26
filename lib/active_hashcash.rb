require "active_hashcash/version"
require "active_hashcash/engine"

# ActiveHashcash protects Rails applications against bots and brute force attacks without annoying humans.
# See the rdoc-ref:README.md for more explanations about Hashcash.
#
# Include this module into your Rails controller.
#
#   class SessionController < ApplicationController
#     include ActiveHashcash
#
#     before_action :check_hashcash, only: :create
#   end
#
# Your are welcome to override most of the methods to customize to your needs.
# For example, if your app runs behind a loab balancer you should probably override #hashcash_ip_address.
#
module ActiveHashcash
  extend ActiveSupport::Concern

  included do
    helper_method :hashcash_hidden_field_tag
  end

  mattr_accessor :resource, instance_accessor: false

  # This is base complexity.
  # Consider lowering it to not exclude people with old and slow devices.
  mattr_accessor :bits, instance_accessor: false, default: 20

  # Flexible complexity penalty rules applied to pushy IP addresses.
  # Each rule must be a hash with:
  # - :period => time window considered (e.g. 5.minutes, 1.hour, 1.day)
  # - :rate => multiplier applied to the number of stamps in that window
  # Rules are applied from shortest to longest period.
  #
  # Example:
  #   ActiveHashcash.penalty_rules = [
  #     {period: 5.minutes, rate: 0.5},
  #     {period: 1.hour, rate: 0.34},
  #     {period: 1.day, rate: 0.25}
  #   ]
  mattr_accessor :penalty_rules, instance_accessor: false, default: [
    {period: 1.hour, rate: 0.5},
    {period: 24.hours, rate: 0.25}
  ]

  mattr_accessor :date_format, instance_accessor: false, default: "%y%m%d"

  # Base controller class used by ActiveHashcash helpers/integration.
  # Override this if your application subclasses the default Rails
  # `ActionController::Base` (e.g. to apply common behavior across controllers).

  # By default ActiveHashcash extends `ActionController::Base`, but you can change it to any controller,
  # such as `AdminController` to handle authentication for the dashboard.
  mattr_accessor :base_controller_class, default: "ActionController::Base"

  # Call that method via a before_action when the form is submitted:
  #
  #   before_action :check_hashcash, only: :create
  #
  # In case of invalid hashcash it calls hashcash_after_failure that you can override.
  # Otherwise, hashcash stamp is stored in database to prevent from double spending.
  def check_hashcash
    attrs = {
      ip_address: hashcash_ip_address,
      request_path: hashcash_request_path,
      context: hashcash_stamp_context
    }
    if hashcash_param && Stamp.spend(hashcash_param, hashcash_resource, hashcash_bits, Date.yesterday, attrs)
      hashcash_after_success
    else
      hashcash_after_failure
    end
  end

  # Returns remote IP address.
  # They are used to automatically increase complexity when the same IP sends many valid hashcash.
  # If you're app is behind a load balancer, you should probably override it to read the right HTTP header.
  def hashcash_ip_address
    request.remote_ip
  end

  # Return current request path to be saved to the sucessful ActiveHash::Stamp.
  # If multiple forms are protected via hashcash this is an interesting info.
  def hashcash_request_path
    request.path
  end

  # Override this method to store custom data for each stamp.
  # It must returns a hash or nil.
  def hashcash_stamp_context
  end

  # This is the resource used to build the hashcash stamp.
  # By default the host name is returned.
  # It' should be good for most cases and prevent from reusing the same stamp between sites.
  def hashcash_resource
    ActiveHashcash.resource || request.host
  end

  # Returns the complexity, the higher the slower it is.
  # Evantully adds a penality for pushy IPs, see hashcash_bits_penality.
  def hashcash_bits
    (ActiveHashcash.bits + hashcash_bits_penality).floor
  end

  # Compute a penality for pushy IPs.
  # The penality rules can be define with `ActiveHashcash.penality_rules`.
  def hashcash_bits_penality
    rules = ActiveHashcash.penalty_rules || []
    periods = rules.map { |rule| rule[:period] }
    counts = ActiveHashcash::Stamp.where(ip_address: hashcash_ip_address).sum_by_periods(periods)
    rules.each_with_index.sum { |rule, index| counts[index].to_i * rule[:rate].to_f }
  end

  # Override if you want to rename the hashcash param.
  def hashcash_param
    params[:hashcash]
  end

  # Override to customize message displayed on submit button while computing hashcash.
  def hashcash_waiting_message
    t("active_hashcash.waiting_label")
  end

  # That method is called when #check_hashcash fails.
  # It raises ActionController::InvalidAuthenticityToken so HTTP response will be 422 by default.
  # Override this method to provide a different behaviour.
  def hashcash_after_failure
    raise ActionController::InvalidAuthenticityToken.new("Invalid hashcash #{hashcash_param}")
  end

  # Maybe you want something special when the hashcash is valid. By default nothing happens.
  def hashcash_after_success
    # Override me for your own needs.
  end

  # Call it inside the form that have to be protected and don't forget to initialize the JavaScript Hascash.setup().
  # Unless you need something really special, you should not need to override this method.
  #
  #   <% form_for model do |form| %>
  #     <%= hashcash_hidden_field_tag %>
  #
  #   <% end %>
  #
  def hashcash_hidden_field_tag(name = :hashcash)
    options = {resource: hashcash_resource, bits: hashcash_bits, waiting_message: hashcash_waiting_message}
    view_context.hidden_field_tag(name, "", "data-hashcash" => options.to_json)
  end
end
