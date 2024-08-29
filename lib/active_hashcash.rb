require "active_hashcash/version"
require "active_hashcash/engine"

module ActiveHashcash
  extend ActiveSupport::Concern

  included do
    helper_method :hashcash_hidden_field_tag
  end

  mattr_accessor :resource, instance_accessor: false

  # This is base complexity.
  # Consider lowering it to not exclude people with old and slow devices.
  mattr_accessor :bits, instance_accessor: false, default: 16

  mattr_accessor :date_format, instance_accessor: false, default: "%y%m%d"

  # Call me via a before_action when the form is submitted : `before_action :check_hashcash, only: :create`
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

  # Override the methods below in your controller, to change any parameter or behaviour.

  def hashcash_ip_address
    request.remote_ip
  end

  def hashcash_request_path
    request.path
  end

  def hashcash_stamp_context
    # Override this method to store custom data for each stamp
  end

  # By default the host name is used as the resource.
  # It' should be good for most cases and prevent from reusing the same stamp between sites.
  def hashcash_resource
    ActiveHashcash.resource || request.host
  end

  # Returns the complexity, the higher the slower it is.
  # Complexity is increased logarithmicly for each IP during the last 24H to slowdown brute force attacks.
  # The minimun value returned is `ActiveHashcash.bits`.
  def hashcash_bits
    if (previous_stamp_count = ActiveHashcash::Stamp.where(ip_address: hashcash_ip_address).where(created_at: 1.day.ago..).count) > 0
      (ActiveHashcash.bits + Math.log2(previous_stamp_count)).floor
    else
      ActiveHashcash.bits
    end
  end

  # Override if you want to rename the hashcash param.
  def hashcash_param
    params[:hashcash]
  end

  # Override to customize message displayed on submit button while computing hashcash.
  def hashcash_waiting_message
    t("active_hashcash.waiting_label")
  end

  # Override to provide a different behaviour when hashcash failed
  def hashcash_after_failure
    raise ActionController::InvalidAuthenticityToken.new("Invalid hashcash #{hashcash_param}")
  end

  # Maybe you want something special when the hashcash is valid. By default nothing happens.
  def hashcash_after_success
    # Override me for your own needs.
  end

  # Call it inside the form that have to be protected and don't forget to initialize the JavaScript Hascash.setup().
  # Unless you need something really special, you should not need to override this method.
  def hashcash_hidden_field_tag(name = :hashcash)
    options = {resource: hashcash_resource, bits: hashcash_bits, waiting_message: hashcash_waiting_message}
    view_context.hidden_field_tag(name, "", "data-hashcash" => options.to_json)
  end
end
