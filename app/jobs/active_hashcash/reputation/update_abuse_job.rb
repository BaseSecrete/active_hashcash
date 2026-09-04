# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAbuseJob < UpdateJob
      # Higher scores first so upsert_score_by_batch keeps the max via uniq.
      URLS = {
        "https://iplists.firehol.org/files/firehol_abusers_1d.netset" => 2,
        "https://iplists.firehol.org/files/firehol_abusers_30d.netset" => 1
      }.freeze

      def perform
        entries = URLS.flat_map { |url, score| normalize(fetch(url), score) }
        raise "Empty list" if entries.empty?
        IPv4.reset_score(:abuse_score, entries)
      end

      def normalize(body, score)
        super(body).map { |ip| [ip, score] }
      end
    end
  end
end
