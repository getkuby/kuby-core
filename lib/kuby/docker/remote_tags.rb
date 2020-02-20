module Kuby
  module Docker
    class RemoteTags
      attr_reader :remote_client, :metadata

      def initialize(remote_client, metadata)
        @remote_client = remote_client
        @metadata = metadata
      end

      def tags
        remote_client.tags
      end

      def latest_tags
        raise NotImplementedError, 'latest tags are not available for remote repos'
      end

      def timestamp_tags
        tags.map { |t| TimestampTag.try_parse(t) }.compact
      end
    end
  end
end
