module ActiveHashcash
  extend ActiveSupport::Concern

  include ActionView::Helpers::FormTagHelper

  included do
    helper_method :hashcash_hidden_field_tag
  end

  mattr_accessor :bits, instance_accessor: false, default: 20
  mattr_accessor :resource, instance_accessor: false
  mattr_accessor :redis_url, instance_accessor: false

  # TODO: protect_from_brute_force bits: 20, exception: ActionController::InvalidAuthenticityToken, with: :handle_failed_hashcash

  # Call me via a before_action when the form is submitted : `before_action :chech_hashcash, only: :create`
  def check_hashcash
    if hashcash_stamp_is_valid? && !hashcash_stamp_spent?
      hashcash_redis.sadd("active_hashcash_stamps".freeze, hashcash_param)
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

  def hashcash_redis
    @hashcash_redis = Redis.new(url: hashcash_redis_url)
  end

  def hashcash_redis_url
    ActiveHashcash.redis_url || ENV["ACTIVE_HASHCASH_REDIS_URL"] || ENV["REDIS_URL"]
  end

  def hashcash_stamp_is_valid?
    stamp = Stamp.parse(hashcash_param)
    stamp.valid? && stamp.bits >= hashcash_bits && stamp.parse_date >= Date.yesterday
  end

  def hashcash_stamp_spent?
    hashcash_redis.sismember("active_hashcash_stamps".freeze, hashcash_param)
  end



  class Engine < ::Rails::Engine
    config.assets.paths << File.expand_path("..", __FILE__)

    config.after_initialize { load_translations }

    def load_translations
      if !I18n.backend.exists?(I18n.locale, "active_hashcash")
        I18n.backend.store_translations(:de, {active_hashcash: {waiting_label: "Warten auf die Überprüfung ..."}})
        I18n.backend.store_translations(:en, {active_hashcash: {waiting_label: "Waiting for verification ..."}})
        I18n.backend.store_translations(:es, {active_hashcash: {waiting_label: "A la espera de la verificación ..."}})
        I18n.backend.store_translations(:fr, {active_hashcash: {waiting_label: "En attente de vérification ..."}})
        I18n.backend.store_translations(:it, {active_hashcash: {waiting_label: "In attesa di verifica ..."}})
        I18n.backend.store_translations(:jp, {active_hashcash: {waiting_label: "検証待ち ..."}})
        I18n.backend.store_translations(:pt, {active_hashcash: {waiting_label: "À espera de verificação ..."}})
      end
    end
  end

  class Stamp
    attr_reader :version, :bits, :date, :resource, :extension, :rand, :counter

    def self.parse(string)
      args = string.split(":")
      new(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
    end

    def self.mint(resource, options = {})
      new(
        options[:version] || 1,
        options[:bits] || ActiveHashcash.bits,
        options[:date] || Date.today.strftime("%y%m%d"),
        resource,
        options[:ext],
        options[:rand] || SecureRandom.alphanumeric(16),
        options[:counter] || 0).work
    end

    def initialize(version, bits, date, resource, extension, rand, counter)
      @version = version
      @bits = bits.to_i
      @date = date.respond_to?(:strftime) ? date.strftime("%y%m%d") : date
      @resource = resource
      @extension = extension
      @rand = rand
      @counter = counter
    end

    def valid?
      Digest::SHA1.hexdigest(to_s).hex >> (160-bits) == 0
    end

    def to_s
      [version, bits, date, resource, extension, rand, counter].join(":")
    end

    def parse_date
      Date.strptime(date, "%y%m%d")
    end

    def work
      @counter += 1 until valid?
      self
    end
  end
end
