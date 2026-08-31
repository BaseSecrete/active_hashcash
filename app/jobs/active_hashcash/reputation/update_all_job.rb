# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    # Call this job in a cron between once per hour or once per day.
    class UpdateAllJob < ApplicationJob
      def perform
        [UpdateTorJob, UpdateSpamhausJob, UpdateIPSumJob].each(&:perform_later)
      end
    end
  end
end
