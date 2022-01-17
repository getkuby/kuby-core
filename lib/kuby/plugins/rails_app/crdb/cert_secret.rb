require 'kube-dsl'

module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class CertSecret < KubeDSL::DSL::V1::Secret
          def initialize(client_cert, ca_cert, base_name, namespace)
            @client_cert = client_cert
            @ca_cert = ca_cert
            @base_name = base_name
            @namespace = namespace

            metadata do
              name "#{base_name}-crdb-#{client_cert.common_name}"
              namespace namespace
            end

            data do
              add 'ca.crt', ca_cert.cert
              add 'tls.crt', client_cert.cert
              add 'tls.key', client_cert.key
            end
          end
        end
      end
    end
  end
end
