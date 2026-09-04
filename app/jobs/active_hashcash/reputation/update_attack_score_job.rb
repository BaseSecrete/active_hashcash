# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAttackScoreJob < UpdateScoreJob
      # Higher scores first so upsert_score keeps the max via uniq.
      URLS = {
        "https://iplists.firehol.org/files/firehol_level1.netset" => 4,
        "https://iplists.firehol.org/files/firehol_level2.netset" => 3,
        "https://iplists.firehol.org/files/firehol_level3.netset" => 2,
        "https://iplists.firehol.org/files/firehol_level4.netset" => 1
      }.freeze
    end
  end
end
