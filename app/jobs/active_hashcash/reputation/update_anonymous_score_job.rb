# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAnonymousScoreJob < UpdateScoreJob
      URLS = {
        "https://iplists.firehol.org/files/firehol_anonymous.netset" => 1
      }.freeze

      def max_body_size
        50.megabytes
      end
    end
  end
end
