# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAllScoresJob < ApplicationJob
      DEFAULT_JOBS = [UpdateAbuseScoreJob, UpdateAnonymousScoreJob, UpdateAttackScoreJob, CleanupJob].freeze

      def perform(jobs = DEFAULT_JOBS.dup)
        if (job = jobs.shift)
          job.perform_now
          self.class.perform_later(jobs) if jobs.any?
        end
      end
    end
  end
end
