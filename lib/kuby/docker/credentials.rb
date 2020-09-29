# typed: strict
require 'kube-dsl'

module Kuby
  module Docker
    class Credentials
      extend ::KubeDSL::ValueFields

      value_fields :username, :password, :email
    end
  end
end
