module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class Client
          attr_reader :username, :cert, :permissions

          def initialize(username, cert, permissions = [])
            @username = username
            @cert = cert
            @permissions = permissions
          end
        end
      end
    end
  end
end
