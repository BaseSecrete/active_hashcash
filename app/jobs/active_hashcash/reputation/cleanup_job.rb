# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class CleanupJob < ApplicationJob
      def perform
        IPv4Address.delete_zero_scores
        IPv4Range.delete_zero_scores
      end
    end
  end
end
