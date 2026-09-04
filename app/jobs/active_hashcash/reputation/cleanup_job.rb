# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class CleanupJob < ApplicationJob
      def perform
        IPv4.delete_zero_scores
      end
    end
  end
end
