# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateIPSumJob < UpdateJob
      def self.url
        "https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"
      end

      def perform
        now = Time.current
        entries = normalize(fetch)
        IPv4.transaction do
          IPv4.where("ipsum_score > 0").update_all(ipsum_score: 0, updated_at: now)
          IPv4.bulk_upsert_scores(entries, score: :ipsum_score, now: now)
        end
        Rails.cache.write(self.class.refreshed_at_key, now)
      end

      def normalize(body)
        super.filter_map do |line|
          ip, score = line.split(/\s+/, 2)
          next unless ip && score

          IPv4.ip_to_range(ip) + [score.to_i]
        end
      end
    end
  end
end
