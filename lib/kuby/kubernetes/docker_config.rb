require 'json'

module Kuby
  module Kubernetes
    class DockerConfig
      extend ValueFields

      value_fields :registry_host, :username, :password, :email

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          registry_host.to_sym => {
            username: username,
            password: password,
            email:    email,
            auth:     Base64.strict_encode64("#{username}:#{password}")
          }
        }
      end
    end
  end
end
