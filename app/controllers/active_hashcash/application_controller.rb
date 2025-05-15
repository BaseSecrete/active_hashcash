module ActiveHashcash
  class ApplicationController < ActiveHashcash.base_controller_class.constantize # :nodoc:
    layout "active_hashcash/application"
  end
end
