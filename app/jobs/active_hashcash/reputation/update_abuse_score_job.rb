# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAbuseScoreJob < UpdateScoreJob
      # Higher scores first so upsert_score_by_batch keeps the max via uniq.
      URLS = {
        "https://iplists.firehol.org/files/firehol_abusers_1d.netset" => 2,
        "https://iplists.firehol.org/files/firehol_abusers_30d.netset" => 1
      }.freeze
    end
  end
end
