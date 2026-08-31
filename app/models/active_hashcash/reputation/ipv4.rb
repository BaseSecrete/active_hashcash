# frozen_string_literal: true

require "ipaddr"

module ActiveHashcash
  module Reputation
    class IPv4 < ApplicationRecord
      self.table_name = "active_hashcash_reputation_ipv4s"

      UPSERT_BATCH_SIZE = 1000

      validates :range_start, :range_end, presence: true, length: {is: 4}
      validates :tor_score, :spamhaus_score, inclusion: {in: 0..1}
      validates :ipsum_score, numericality: {only_integer: true, greater_than_or_equal_to: 0}

      def self.scores(ip)
        ip_binary = ActiveRecord::Type::Binary.new.serialize(IPAddr.new(ip).hton)
        tor_score, spamhaus_score, ipsum_score = where("? BETWEEN range_start AND range_end", ip_binary)
          .pick(Arel.sql("sum(tor_score), sum(spamhaus_score), sum(ipsum_score)"))
        {tor: tor_score || 0, spamhaus: spamhaus_score || 0, ipsum: ipsum_score || 0}
      rescue IPAddr::InvalidAddressError
        {tor: 0, spamhaus: 0, ipsum: 0}
      end

      def self.bulk_upsert_scores(entries, score_column, timestamp)
        entries = entries.uniq { |range_start, range_end, _| [range_start, range_end] }
        entries.each_slice(UPSERT_BATCH_SIZE) do |batch|
          upsert_all(
            batch.map do |range_start, range_end, value|
              {
                range_start: range_start,
                range_end: range_end,
                created_at: timestamp,
                updated_at: timestamp,
                score_column => value
              }
            end,
            record_timestamps: false,
            unique_by: [:range_start, :range_end],
            update_only: [score_column, :updated_at]
          )
        end
      end

      def self.ip_to_range(string)
        if (ip = IPAddr.new(string)).ipv4?
          [binary = ip.hton, binary]
        end
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
