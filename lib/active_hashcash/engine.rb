module ActiveHashcash
  class Engine < ::Rails::Engine # :nodoc:
    config.assets.paths << File.expand_path("../..", __FILE__) if config.respond_to?(:assets)

    isolate_namespace ActiveHashcash
  end
end
