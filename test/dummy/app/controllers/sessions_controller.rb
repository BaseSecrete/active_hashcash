class SessionsController < ApplicationController
  include ActiveHashcash

  before_action :check_hashcash, only: :create

  def index
  end

  def create
    render(inline: "OK")
  end

  def hashcash_stamp_context
    {more: "details"}
  end

  def hashcash_bits
    # Don't do this on real app, this is not secure but convenient for testing
    params[:bits].presence || super
  end

end
