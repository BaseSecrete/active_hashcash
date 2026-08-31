module ActiveHashcash
  class Engine < ::Rails::Engine # :nodoc:
    config.assets.paths << File.expand_path("../..", __FILE__) if config.respond_to?(:assets)

    isolate_namespace ActiveHashcash

    initializer "active_hashcash.inflections" do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "IPv4"
        inflect.acronym "IPSum"
      end
    end
  end
end
