# frozen_string_literal: true

require "ipaddr"

module ActiveHashcash
  module Reputation
    class IPv4 < ApplicationRecord
      self.table_name = "active_hashcash_reputation_ipv4s"

      validates :range_start, :range_end, presence: true, length: {is: 4}
      validates :anonymous_score, inclusion: {in: 0..1}
      validates :abuse_score, inclusion: {in: 0..2}
      validates :attack_score, inclusion: {in: 0..4}

      scope :by_address, -> (string) {
        where("? BETWEEN range_start AND range_end", ActiveRecord::Type::Binary.new.serialize(IPAddr.new(string).hton))
      }

      def self.scores(ip)
        abuse, anonymous, attack = by_address(ip).pick(Arel.sql("sum(abuse_score), sum(anonymous_score), sum(attack_score)"))
        {abuse: abuse || 0, anonymous: anonymous || 0, attack: attack || 0}
      rescue IPAddr::InvalidAddressError
        {abuse: 0, anonymous: 0, attack: 0}
      end

      def self.reset_score(column, entries)
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
            {range_start: range.first.hton, range_end: range.last.hton, column => value}
          end,
          record_timestamps: false,
          unique_by: [:range_start, :range_end],
          update_only: [column]
        )
      end
    end
  end
end
