module ActiveHashcash
  class Engine < ::Rails::Engine
    config.assets.paths << File.expand_path("../..", __FILE__)

    isolate_namespace ActiveHashcash
  end
end
