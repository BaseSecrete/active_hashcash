# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateSpamhausJob < UpdateJob
      def self.url
        "https://www.spamhaus.org/drop/drop.txt"
      end

      def perform
        raise "Empty list" if (entries = normalize(fetch)).empty?
        IPv4.transaction do
          IPv4.where(spamhaus_score: 1).update_all(spamhaus_score: 0)
          IPv4.bulk_upsert_scores(entries, :spamhaus_score)
        end
      end

      def normalize(body)
        super.filter_map do |line|
          cidr = line.split(/[\s;]/, 2).first
          IPv4.cidr_to_range(cidr) + [1] if cidr.present?
        end
      end
    end
  end
end
