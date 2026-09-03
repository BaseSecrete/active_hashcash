# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAttackJob < UpdateJob
      # Higher scores first so bulk_upsert_scores keeps the max via uniq.
      URLS = {
        "https://iplists.firehol.org/files/firehol_level1.netset" => 4,
        "https://iplists.firehol.org/files/firehol_level2.netset" => 3,
        "https://iplists.firehol.org/files/firehol_level3.netset" => 2,
        "https://iplists.firehol.org/files/firehol_level4.netset" => 1
      }.freeze

      def perform
        entries = URLS.flat_map { |url, score| normalize(fetch(url), score) }
        raise "Empty list" if entries.empty?
        IPv4.transaction do
          IPv4.where("attack_score > 0").update_all(attack_score: 0)
          IPv4.bulk_upsert_scores(entries, :attack_score)
        end
      end

      def normalize(body, score)
        super(body).filter_map do |ip|
          range = ip.to_range
          range = [range.first.hton, range.last.hton]
          range + [score] if range
        end
      end
    end
  end
end
