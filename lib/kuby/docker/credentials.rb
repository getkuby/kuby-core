module Kuby
  module Docker
    class Credentials
      extend ValueFields

      value_fields :username, :password, :email
    end
  end
end
