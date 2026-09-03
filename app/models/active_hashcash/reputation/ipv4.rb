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

      def self.scores(ip)
        ip_binary = ActiveRecord::Type::Binary.new.serialize(IPAddr.new(ip).hton)
        abuse_score, anonymous_score, attack_score =
          where("? BETWEEN range_start AND range_end", ip_binary)
            .pick(Arel.sql("sum(abuse_score), sum(anonymous_score), sum(attack_score)"))
        {abuse: abuse_score || 0, anonymous: anonymous_score || 0, attack: attack_score || 0}
      rescue IPAddr::InvalidAddressError
        {abuse: 0, anonymous: 0, attack: 0}
      end

      def self.bulk_upsert_scores(entries, score_column)
        entries = entries.uniq { |range_start, range_end, _| [range_start, range_end] }
        entries.each_slice(UPSERT_BATCH_SIZE) do |batch|
          upsert_all(
            batch.map do |range_start, range_end, value|
              {
                range_start: range_start,
                range_end: range_end,
                score_column => value
              }
            end,
            record_timestamps: false,
            unique_by: [:range_start, :range_end],
            update_only: [score_column]
          )
        end
      end

      def self.ip_to_range(string)
        if (ip = IPAddr.new(string)).ipv4?
          [binary = ip.hton, binary]
        end
      end

      # Handles both unique IPs and network masks (CIDR).
      def self.net_to_range(string)
        string.include?("/") ? cidr_to_range(string) : ip_to_range(string)
      end

      def self.cidr_to_range(cidr)
        network = IPAddr.new(cidr)
        prefix = network.prefix
        start_int = network.to_i
        end_int = start_int | ((1 << (32 - prefix)) - 1)
        [pack_int(start_int), pack_int(end_int)]
      end

      def self.pack_int(int)
        [int].pack("N")
      end
    end
  end
end
