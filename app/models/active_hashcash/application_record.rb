module ActiveHashcash
  class ApplicationRecord < ActiveRecord::Base # :nodoc:
    self.abstract_class = true
  end
end
