# frozen_string_literal: true

require "ipaddr"
require "net/http"
require "uri"

module ActiveHashcash
  module Reputation
    class UpdateJob < ApplicationJob
      def self.url
        raise NotImplementedError, "#{name} must implement .url"
      end

      def fetch(url = self.class.url)
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

      PRIVATE_RANGES = [
        IPAddr.new("10.0.0.0/8"),
        IPAddr.new("172.16.0.0/12"),
        IPAddr.new("192.168.0.0/16"),
        IPAddr.new("127.0.0.0/8"),
        IPAddr.new("0.0.0.0/8"),
        IPAddr.new("169.254.0.0/16"),
        IPAddr.new("100.64.0.0/10")
      ].freeze

      def normalize(body)
        body.each_line.filter_map do |line|
          line = line.strip
          next if line.blank? || line.start_with?("#", ";")
          next if private_ip?(line)
          line
        end
      end

      def private_ip?(line)
        ip = IPAddr.new(line.split("/").first)
        PRIVATE_RANGES.any? { |range| range.include?(ip) }
      rescue IPAddr::InvalidAddressError
        false
      end
    end
  end
end
