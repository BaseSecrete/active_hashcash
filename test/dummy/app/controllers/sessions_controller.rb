class SessionsController < ApplicationController
  include ActiveHashcash::Concern

  before_action :check_hashcash

  def create
    head(:ok)
  end

  def hashcash_stamp_context
    {more: "details"}
  end

end
