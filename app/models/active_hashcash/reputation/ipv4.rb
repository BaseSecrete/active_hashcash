# frozen_string_literal: true

require "ipaddr"

module ActiveHashcash
  module Reputation
    class IPv4 < ApplicationRecord
      self.table_name = "active_hashcash_reputation_ipv4s"

      UPSERT_BATCH_SIZE = 1000

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

      def self.bulk_upsert_scores(entries, score_column)
        entries = entries.uniq { |range_start, range_end, _| [range_start, range_end] }
        entries.each_slice(UPSERT_BATCH_SIZE) do |batch|
          upsert_all(
            batch.map do |range_start, range_end, value|
              {range_start: range_start, range_end: range_end, score_column => value}
            end,
            record_timestamps: false,
            unique_by: [:range_start, :range_end],
            update_only: [score_column]
          )
        end
      end
    end
  end
end
