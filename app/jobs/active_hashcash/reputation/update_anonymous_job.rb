# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAnonymousJob < UpdateJob
      def self.url
        "https://iplists.firehol.org/files/firehol_anonymous.netset"
      end

      def perform
        raise "Empty list" if (entries = normalize(fetch)).empty?
        IPv4.reset_score(:anonymous_score, entries)
      end

      def max_body_size
        50.megabytes
      end

      def normalize(body)
        super.map { |ip| [ip, 1] }
      end
    end
  end
end
