module Kuby
  module Docker
    class TimestampedImage < Image
      LATEST_TAG = 'latest'.freeze

      def new_version
        @new_version ||= duplicate_with_tags(
          TimestampTag.new(Time.now).to_s, [LATEST_TAG]
        )
      end

      def current_version
        @current_version ||= duplicate_with_tags(
          tags.latest_timestamp_tag, [LATEST_TAG]
        )
      end

      def previous_version
        @previous_version ||= duplicate_with_tags(
          tags.previous_timestamp_tag, []
        )
      end

      private

      # sig { returns(CLI) }
      def cli
        @cli ||= Docker::CLI.new
      end

      # sig { returns(::Docker::Remote::Client) }
      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          image_host, image_repo, credentials.username, credentials.password,
        )
      end

      # sig { returns(Tags) }
      def tags
        @tags ||= Tags.new(cli, remote_client, image_url)
      end
    end
  end
end
