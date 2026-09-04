# frozen_string_literal: true

require "ipaddr"

module ActiveHashcash
  module Reputation
    class IPv4Address < ApplicationRecord
      self.table_name = "active_hashcash_reputation_ipv4_addresses"

      validates :id, presence: true, length: {is: 4}
      validates :anonymous_score, inclusion: {in: 0..1}
      validates :abuse_score, inclusion: {in: 0..2}
      validates :attack_score, inclusion: {in: 0..4}

      def self.scores(ip)
        abuse, anonymous, attack = where(id: ActiveRecord::Type::Binary.new.serialize(IPAddr.new(ip).hton)).pick(:abuse_score, :anonymous_score, :attack_score)
        {abuse: abuse || 0, anonymous: anonymous || 0, attack: attack || 0}
      rescue IPAddr::InvalidAddressError
        {abuse: 0, anonymous: 0, attack: 0}
      end

      def self.reset_score(name, entries)
        column = :"#{name}_score"
        entries.uniq! { |ip, _| ip }
        transaction do
          where(column => 1..).update_all(column => 0)
          entries.each_slice(10_000) { |batch| upsert_score(column, batch) }
        end
      end

      def self.upsert_score(column, entries)
        upsert_all(
          entries.map { |ip, value| {id: ip.hton, column => value} },
          record_timestamps: false,
          update_only: [column]
        )
      end

      def self.delete_zero_scores
        where(anonymous_score: 0, abuse_score: 0, attack_score: 0).delete_all
      end
    end
  end
end
