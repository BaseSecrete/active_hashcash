# frozen_string_literal: true

require "net/http"
require "uri"

module ActiveHashcash
  class UpdateTorExitIpsJob < ApplicationJob
    URL = "https://check.torproject.org/torbulkexitlist"
    CACHE_KEY = "ActiveHashcash::tor_exit_ips"
    ENQUEUED_KEY = "ActiveHashcash::tor_exit_ips_enqueued"

    def self.perform_later_once
      perform_later if Rails.cache.write(ENQUEUED_KEY, true, unless_exist: true)
    end

    def perform
      body = Net::HTTP.get(URI(URL))
      ips = body.each_line.map(&:strip).reject(&:empty?).sort
      Rails.cache.write(CACHE_KEY, {updated_at: Time.current, ips: ips})
      self.class.set(wait: 1.hour).perform_later
    ensure
      Rails.cache.delete(ENQUEUED_KEY)
    end
  end
end
