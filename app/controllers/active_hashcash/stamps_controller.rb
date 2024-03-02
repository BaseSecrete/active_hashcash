module ActiveHashcash
  class StampsController < ApplicationController
    def index
      @stamps = Stamp.filter_by(params).order(created_at: :desc).limit(100)
    end

    def show
      @stamp = Stamp.find(params[:id])
    end
  end
end
