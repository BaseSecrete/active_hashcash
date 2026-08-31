# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateTorJob < UpdateJob
      def self.url
        "https://check.torproject.org/torbulkexitlist"
      end

      def perform
        now = Time.current
        entries = normalize(fetch)

        IPv4.transaction do
          IPv4.where(tor_score: 1).update_all(tor_score: 0, updated_at: now)
          IPv4.bulk_upsert_scores(entries, score: :tor_score, now: now)
        end
        Rails.cache.write(self.class.refreshed_at_key, now)
      end

      def normalize(body)
        super.map { |ip| IPv4.ip_to_range(ip) + [1] }
      end
    end
  end
end
