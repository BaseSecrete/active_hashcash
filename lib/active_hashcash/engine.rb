module ActiveHashcash
  class Engine < ::Rails::Engine # :nodoc:
    isolate_namespace ActiveHashcash

    initializer "active_hashcash.inflections" do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "IPv4"
      end
    end
  end
end
