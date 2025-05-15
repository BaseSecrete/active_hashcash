module ActiveHashcash
  class StampsController < ApplicationController # :nodoc:
    def index
      @stamps = Stamp.filter_by(params).order(created_at: :desc).limit(1000)
    end

    def show
      @stamp = Stamp.find(params[:id])
    end
  end
end
