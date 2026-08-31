# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateIPSumJob < UpdateJob
      def self.url
        "https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"
      end

      def perform
        timestamp = Time.current
        entries = normalize(fetch)
        IPv4.transaction do
          IPv4.where("ipsum_score > 0").update_all(ipsum_score: 0, updated_at: timestamp)
          IPv4.bulk_upsert_scores(entries, :ipsum_score, timestamp)
        end
      end

      def normalize(body)
        super.filter_map do |line|
          ip, score = line.split(/\s+/, 2)
          IPv4.ip_to_range(ip) + [score.to_i] if ip && score
        end
      end
    end
  end
end
