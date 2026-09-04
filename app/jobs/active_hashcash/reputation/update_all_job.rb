# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    class UpdateAllJob < ApplicationJob
      def perform(jobs = UpdateJob.subclasses + [CleanupJob])
        if (job = jobs.shift)
          job.perform_now
          self.class.perform_later(jobs) if jobs.any?
        end
      end
    end
  end
end
