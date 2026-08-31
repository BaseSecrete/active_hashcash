# frozen_string_literal: true

require "net/http"
require "uri"

module ActiveHashcash
  module Reputation
    class UpdateJob < ApplicationJob
      around_perform do |_job, block|
        block.call
      ensure
        Rails.cache.delete(self.class.enqueued_key)
      end

      def self.perform_later_once
        perform_later if Rails.cache.write(enqueued_key, true, unless_exist: true)
      end

      def self.last_refreshed_at
        Rails.cache.read(refreshed_at_key)
      end

      def self.url
        raise NotImplementedError, "#{name} must implement .url"
      end

      def self.enqueued_key
        "#{name}_enqueued"
      end

      def self.refreshed_at_key
        "#{name}_refreshed_at"
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
        100.megabytes
      end

      def normalize(body)
        body.each_line.filter_map do |line|
          line = line.strip
          line if line.present? && !line.start_with?("#", ";")
        end
      end
    end
  end
end
