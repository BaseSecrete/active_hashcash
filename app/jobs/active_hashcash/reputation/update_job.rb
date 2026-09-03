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

      def normalize(body)
        body.each_line.filter_map do |line|
          next if (line = line.strip).blank? || line.start_with?("#", ";")
          next if (ip = IPAddr.new(line)).private? || ip.loopback? || ip.link_local?
          line
        rescue IPAddr::InvalidAddressError
          next
        end
      end
    end
  end
end
