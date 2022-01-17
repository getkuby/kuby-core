require 'openssl'

module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class Keypair
          attr_reader :cert, :key

          def initialize(cert, key)
            @cert = cert
            @key = key
          end
        end
      end
    end
  end
end
