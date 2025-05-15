# frozen_string_literal: true

module ActiveHashcash
  # This is the model to store hashcash stamps.
  # Unless you need something really specific, you should not need interact directly with that class.
  class Stamp < ApplicationRecord
    validates_presence_of :version, :bits, :date, :resource, :rand, :counter

    scope :created_from, -> (date) { where(created_at: date..) }
    scope :created_to, -> (date) { where(created_at: ..date) }

    scope :bits_from, -> (value) { where(bits: value..) }
    scope :bits_to, -> (value) { where(bits: ..value) }

    scope :ip_address_starts_with, -> (string) { where("ip_address LIKE ?", sanitize_sql_like(string) + "%") }
    scope :request_path_starts_with, -> (string) { where("request_path LIKE ?", sanitize_sql_like(string) + "%") }

    def self.filter_by(params)
      scope = all
      scope = scope.request_path_starts_with(params[:request_path_starts_with]) if params[:request_path_starts_with].present?
      scope = scope.ip_address_starts_with(params[:ip_address_starts_with]) if params[:ip_address_starts_with].present?
      scope = scope.created_from(params[:created_from]) if params[:created_from].present?
      scope = scope.created_to(params[:created_to]) if params[:created_to].present?
      scope = scope.bits_from(params[:bits_from]) if params[:bits_from].present?
      scope = scope.bits_to(params[:bits_to]) if params[:bits_to].present?
      scope
    end

    # Verify and save the hashcash stamp.
    # Saving in the database prevent from double spending the same stamp.
    def self.spend(string, resource, bits, date, options = {})
      return false unless stamp = parse(string)
      stamp.attributes = options
      stamp.verify(resource, bits, date) && stamp.save
    rescue ActiveRecord::RecordNotUnique
      false
    end

    # Pare and instanciate a stamp from a sting which respects the hashcash format:
    #
    #   ver:bits:date:resource:[ext]:rand:counter
    def self.parse(string)
      args = string.to_s.split(":")
      return if args.size != 7
      new(version: args[0], bits: args[1], date: Date.strptime(args[2], ActiveHashcash.date_format), resource: args[3], ext: args[4], rand: args[5], counter: args[6])
    end

    def self.mint(resource, attributes = {})
      new({
        version: 1,
        bits: ActiveHashcash.bits,
        date: Date.today.strftime(ActiveHashcash.date_format),
        resource: resource,
        rand: SecureRandom.alphanumeric(16),
        counter: 0,
      }.merge(attributes)).work
    end

    def work
      counter.next! until authentic?
      self
    end

    def authentic?
      Digest::SHA1.hexdigest(to_s).hex >> (160-bits) == 0
    end

    def verify(resource, bits, date)
      self.resource == resource && self.bits >= bits && self.date >= date && !self.date.future? && authentic?
    end

    def to_s
      [version.to_i, bits, date.strftime("%y%m%d"), resource, ext, rand, counter].join(":")
    end
  end
end
