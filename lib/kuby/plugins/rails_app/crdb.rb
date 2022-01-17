module Kuby
  module Plugins
    module RailsApp
      module CRDB
        autoload :Cert,              'kuby/plugins/rails_app/crdb/cert'
        autoload :CertSecret,        'kuby/plugins/rails_app/crdb/cert_secret'
        autoload :ClientKeypair,     'kuby/plugins/rails_app/crdb/client_keypair'
        autoload :ClientSet,         'kuby/plugins/rails_app/crdb/client_set'
        autoload :Client,            'kuby/plugins/rails_app/crdb/client'
        autoload :Keypair,           'kuby/plugins/rails_app/crdb/keypair'
        autoload :NodeKeypair,       'kuby/plugins/rails_app/crdb/node_keypair'
        autoload :Plugin,            'kuby/plugins/rails_app/crdb/plugin'
        autoload :SelfSignedKeypair, 'kuby/plugins/rails_app/crdb/self_signed_keypair'
      end
    end
  end
end
