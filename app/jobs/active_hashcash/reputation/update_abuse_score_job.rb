# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAbuseScoreJob < UpdateScoreJob
      # Higher scores first so upsert_score keeps the max via uniq.
      URLS = {
        "https://iplists.firehol.org/files/firehol_abusers_1d.netset" => 2,
        "https://netapi.com/api2/?method=compromised&dataset_type=ip&category=B,D" => 2,
        "https://iplists.firehol.org/files/firehol_abusers_30d.netset" => 1,
        "https://netapi.com/api2/?method=compromised&dataset_type=ip-all&window=30d&category=B,D" => 1
      }.freeze
    end
  end
end
