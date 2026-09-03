# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAnonymousJob < UpdateJob
      def self.url
        "https://iplists.firehol.org/files/firehol_anonymous.netset"
      end

      def perform
        raise "Empty list" if (entries = normalize(fetch)).empty?
        IPv4.transaction do
          IPv4.where(anonymous_score: 1).update_all(anonymous_score: 0)
          IPv4.bulk_upsert_scores(entries, :anonymous_score)
        end
      end

      def max_body_size
        50.megabytes
      end

      def normalize(body)
        super.filter_map do |ip|
          range = IPv4.net_to_range(ip)
          range + [1] if range
        end
      end
    end
  end
end
