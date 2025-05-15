module ActiveHashcash
  class AddressesController < ApplicationController # :nodoc:
    def index
      @addresses = Stamp.filter_by(params).group(:ip_address).order(count_all: :desc).limit(1000).count
    end
  end
end
