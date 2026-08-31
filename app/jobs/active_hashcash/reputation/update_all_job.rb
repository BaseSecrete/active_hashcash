# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAllJob < ApplicationJob
      def perform
        [UpdateTorJob, UpdateSpamhausJob, UpdateIPSumJob].each(&:perform_later)
        # TODO: Delete IPs with empty score
      end
    end
  end
end
