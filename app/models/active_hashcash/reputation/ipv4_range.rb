# frozen_string_literal: true

require "ipaddr"

module ActiveHashcash
  module Reputation
    class IPv4Range < ApplicationRecord
      self.table_name = "active_hashcash_reputation_ipv4_ranges"

      MIN_PREFIX = 16 # Reject nets too large

      validates :first_address, :last_address, presence: true, length: {is: 4}
      validates :anonymous_score, inclusion: {in: 0..1}
      validates :abuse_score, inclusion: {in: 0..2}
      validates :attack_score, inclusion: {in: 0..4}

      # PK probes for ancestor CIDRs /MIN_PREFIX../32 (wider prefixes are ignored).
      scope :by_address, -> (string) {
        ip = IPAddr.new(string)
        binary = ActiveRecord::Type::Binary.new
        pairs = (MIN_PREFIX..32).map do |prefix|
          range = IPAddr.new("#{ip}/#{prefix}").to_range
          [binary.serialize(range.first.hton), binary.serialize(range.last.hton)]
        end
        where(pairs.map { "(first_address = ? AND last_address = ?)" }.join(" OR "), *pairs.flatten)
      }

      def self.scores(ip)
        abuse, anonymous, attack = by_address(ip).pick(Arel.sql("max(abuse_score), max(anonymous_score), max(attack_score)"))
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
          entries.map do |ip, value|
            range = ip.to_range
            {first_address: range.first.hton, last_address: range.last.hton, column => value}
          end,
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
