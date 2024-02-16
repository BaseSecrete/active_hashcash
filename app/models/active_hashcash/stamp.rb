# frozen_string_literal: true

module ActiveHashcash
  class Stamp < ApplicationRecord
    validates_presence_of :version, :bits, :date, :resource, :rand, :counter

    def self.spend(string, resource, bits, date, ip_address = nil)
      stamp = parse(string)
      stamp.ip_address = ip_address
      stamp.verify(resource, bits, date) && stamp.save
    rescue ActiveRecord::RecordNotUnique
      false
    end

    def self.parse(string)
      args = string.split(":")
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
