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
          latest_timestamp_tag.to_s, [LATEST_TAG]
        )
      end

      def previous_version(current_tag = nil)
        @previous_version ||= duplicate_with_tags(
          previous_timestamp_tag(current_tag).to_s, []
        )
      end

      def previous_timestamp_tag(current_tag = nil)
        current_tag = TimestampTag.try_parse(current_tag || latest_timestamp_tag)
        return nil unless current_tag

        all_tags = timestamp_tags.sort

        idx = all_tags.index do |tag|
          tag.time == current_tag.time
        end

        idx ||= 0
        return nil unless idx > 0

        all_tags[idx - 1]
      end

      def latest_timestamp_tag
        timestamp_tags.sort.last
      end

      def build(build_args = {})
        docker_cli.build(new_version, build_args)
        @current_version = new_version
        @new_version = nil
      end

      def push(tag)
        docker_cli.push(image_url, tag)
      end

      private

      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          image_host, image_repo, credentials.username, credentials.password,
        )
      end

      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      def local
        @local ||= LocalTags.new(docker_cli, image_url)
      end

      def remote
        @remote ||= RemoteTags.new(remote_client, image_url)
      end
    end
  end
end
