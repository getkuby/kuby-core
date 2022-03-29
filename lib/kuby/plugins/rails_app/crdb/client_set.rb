module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class ClientSet
          include Enumerable

          ORG = 'Kuby'.freeze
          CA_COMMON_NAME = 'ca'.freeze
          NODE_COMMON_NAME = 'node'.freeze

          attr_reader :base_path, :base_name, :namespace, :master_key

          def initialize(base_path:, base_name:, namespace:, master_key:)
            @base_path = base_path
            @base_name = base_name
            @namespace = namespace
            @master_key = master_key
            @clients = {}
          end

          def ca_cert
            @ca_cert ||= Cert.new(base_path, master_key, CA_COMMON_NAME) do
              SelfSignedKeypair.create(ORG, CA_COMMON_NAME)
            end
          end

          def node_cert
            @node_cert ||= Cert.new(base_path, master_key, NODE_COMMON_NAME) do
              NodeKeypair.create(
                ca_cert.cert, ca_cert.key, ORG, NODE_COMMON_NAME, node_alt_names
              )
            end
          end

          def make_node_secret
            CertSecret.new(node_cert, ca_cert, base_name, namespace)
          end

          def add(username, permissions = [])
            @clients[username] = begin
              client_cert = Cert.new(base_path, master_key, username) do
                ClientKeypair.create(ca_cert.cert, ca_cert.key, ORG, username)
              end

              Client.new(username, client_cert, permissions)
            end
          end

          def [](username)
            @clients[username]
          end

          def each(&block)
            @clients.each(&block)
          end

          def each_cert
            return to_enum(__method__) unless block_given?

            yield ca_cert
            yield node_cert

            each do |_, client|
              yield client.cert
            end
          end

          def make_client_secret(username)
            CertSecret.new(
              @clients[username].cert, ca_cert, base_name, namespace
            )
          end

          private

          def node_alt_names
            @node_alt_names ||= [
              'DNS:localhost',
              "DNS:#{svc_name}-public",
              "DNS:#{svc_name}-public.#{namespace}",
              "DNS:#{svc_name}-public.#{namespace}.svc.cluster.local",
              "DNS:*.#{svc_name}",
              "DNS:*.#{svc_name}.#{namespace}",
              "DNS:*.#{svc_name}.#{namespace}.svc.cluster.local",
              'IP:127.0.0.1'
            ]
          end

          def svc_name
            @svc_name ||= "#{base_name}-crdb"
          end
        end
      end
    end
  end
end
