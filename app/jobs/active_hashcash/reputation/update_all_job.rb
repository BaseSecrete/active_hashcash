# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAllJob < ApplicationJob
      def perform
        [UpdateTorJob, UpdateSpamhausJob, UpdateIPSumJob, UpdateAbuseJob, UpdateAnonymousJob, UpdateAttackJob].each(&:perform_later)
        # TODO: Delete IPs with empty score after update
      end
    end
  end
end
