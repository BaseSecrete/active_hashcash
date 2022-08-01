module ActiveHashcash
  class Engine < ::Rails::Engine
    config.assets.paths << File.expand_path("../..", __FILE__)

    config.after_initialize { load_translations }

    def load_translations
      if !I18n.backend.exists?(I18n.locale, "active_hashcash")
        I18n.backend.store_translations(:de, {active_hashcash: {waiting_label: "Warten auf die Überprüfung ..."}})
        I18n.backend.store_translations(:en, {active_hashcash: {waiting_label: "Waiting for verification ..."}})
        I18n.backend.store_translations(:es, {active_hashcash: {waiting_label: "A la espera de la verificación ..."}})
        I18n.backend.store_translations(:fr, {active_hashcash: {waiting_label: "En attente de vérification ..."}})
        I18n.backend.store_translations(:it, {active_hashcash: {waiting_label: "In attesa di verifica ..."}})
        I18n.backend.store_translations(:jp, {active_hashcash: {waiting_label: "検証待ち ..."}})
        I18n.backend.store_translations(:pt, {active_hashcash: {waiting_label: "À espera de verificação ..."}})
      end
    end
  end
end
