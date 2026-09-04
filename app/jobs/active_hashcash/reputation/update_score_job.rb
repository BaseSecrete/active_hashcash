# frozen_string_literal: true

require "ipaddr"
require "net/http"
require "uri"

module ActiveHashcash
  module Reputation
    class UpdateScoreJob < ApplicationJob
      def perform
        entries = self.class::URLS.flat_map { |url, score| normalize(fetch(url), score) }
        raise "Empty list" if entries.empty?
        addresses, ranges = entries.partition { |ip, _| ip.prefix == 32 }
        IPv4Address.transaction do
          IPv4Address.reset_score(score_name, addresses)
          IPv4Range.reset_score(score_name, ranges)
        end
      end

      def score_name
        self.class.name[/Update(\w*)ScoreJob/, 1].downcase.to_sym
      end

      def fetch(url)
        uri = URI(url)
        body = +""

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: open_timeout, read_timeout: read_timeout) do |http|
          http.request(Net::HTTP::Get.new(uri)) do |response|
            response.error! unless response.is_a?(Net::HTTPSuccess)
            response.read_body do |chunk|
              body << chunk
              raise "Response body exceeds #{max_body_size} bytes" if body.bytesize > max_body_size
            end
          end
        end

        body
      end

      def open_timeout
        5
      end

      def read_timeout
        10
      end

      def max_body_size
        10.megabytes
      end

      def normalize(body, score)
        body.each_line.filter_map do |line|
          next if (line = line.strip).blank? || line.start_with?("#", ";")
          next if (ip = IPAddr.new(line)).private? || ip.loopback? || ip.link_local? || !ip.ipv4? || ip.prefix < 16
          [ip, score]
        rescue IPAddr::InvalidAddressError
          next
        end
      end
    end
  end
end
