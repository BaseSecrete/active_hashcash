module ActiveHashcash
  extend ActiveSupport::Concern

  include ActionView::Helpers::FormTagHelper

  included do
    helper_method :hashcash_hidden_field_tag
  end

  mattr_accessor :bits, instance_accessor: false, default: 20
  mattr_accessor :resource, instance_accessor: false
  mattr_accessor :redis_url, instance_accessor: false, default: ENV["ACTIVE_HASHCASH_REDIS_URL"] || ENV["REDIS_URL"]

  def self.store
    @store ||= Store.new(Redis.new(url: ActiveHashcash.redis_url))
  end

  def self.store=(store)
    @store = store
  end

  # TODO: protect_from_brute_force bits: 20, exception: ActionController::InvalidAuthenticityToken, with: :handle_failed_hashcash

  # Call me via a before_action when the form is submitted : `before_action :chech_hashcash, only: :create`
  def check_hashcash
    stamp = hashcash_param && Stamp.parse(hashcash_param)
    if stamp && stamp.verify(hashcash_resource, hashcash_bits, Date.yesterday) && ActiveHashcash.store.add?(stamp)
      hashcash_after_success
    else
      hashcash_after_failure
    end
  end

  # Override the methods below in your controller, to change any parameter of behaviour.

  # By default the host name is used as the resource.
  # It' should be good for most cases and prevent from reusing the same stamp between sites.
  def hashcash_resource
    ActiveHashcash.resource || request.host
  end

  # Define the complexity, the higher the slower it is. Consider lowering this value to not exclude people with old and slow devices.
  # On a decent laptop, it takes around 30 seconds for the JavaScript implementation to solve a 20 bits complexity and few seconds when it's 16.
  def hashcash_bits
    ActiveHashcash.bits
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
    hidden_field_tag(name, "", "data-hashcash" => options.to_json)
  end
end

require "active_hashcash/stamp"
require "active_hashcash/store"
require "active_hashcash/engine"
