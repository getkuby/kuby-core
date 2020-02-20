module Kuby
  module Docker
    class Tags
      LATEST = Metadata::LATEST_TAG

      attr_reader :cli, :remote_client, :metadata

      def initialize(cli, remote_client, metadata)
        @cli = cli
        @remote_client = remote_client
        @metadata = metadata
      end

      def tags
        (local.tags + remote.tags).uniq
      end

      def latest_tags
        (local.latest_tags + remote.latest_tags).uniq
      end

      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      def all
        self
      end

      def local
        @local ||= LocalTags.new(cli, metadata)
      end

      def remote
        @remote ||= RemoteTags.new(remote_client, metadata)
      end
    end
  end
end
