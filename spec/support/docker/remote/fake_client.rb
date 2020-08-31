module Docker
  module Remote
    class FakeClient
      attr_reader :registry_url, :repo, :username, :password
      attr_accessor :tags

      def initialize(registry_url, repo, username = nil, password = nil)
        @registry_url = registry_url
        @repo = repo
        @username = username
        @password = password
        @tags = []
      end
    end
  end
end
