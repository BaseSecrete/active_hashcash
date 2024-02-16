module ActiveHashcash
  class StampsController < ApplicationController
    def index
      @stamps = Stamp.order(created_at: :desc).limit(100)
    end
  end
end
