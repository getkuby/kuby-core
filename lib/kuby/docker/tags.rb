# typed: strict

module Kuby
  module Docker
    class Tags
      extend T::Sig

      LATEST = Metadata::LATEST_TAG

      sig { returns(CLI) }
      attr_reader :cli

      sig { returns(::Docker::Remote::Client) }
      attr_reader :remote_client

      sig { returns(String) }
      attr_reader :image_url

      sig {
        params(
          cli: CLI,
          remote_client: ::Docker::Remote::Client,
          image_url: String
        )
        .void
      }
      def initialize(cli, remote_client, image_url)
        @cli = cli
        @remote_client = remote_client
        @image_url = image_url

        @local = T.let(@local, T.nilable(LocalTags))
        @remote = T.let(@remote, T.nilable(RemoteTags))
        @latest_timestamp_tag = T.let(@latest_timestamp_tag, T.nilable(TimestampTag))
      end

      sig { returns(T::Array[String]) }
      def tags
        (local.tags + remote.tags).uniq
      end

      sig { returns(T::Array[String]) }
      def latest_tags
        (local.latest_tags + remote.latest_tags).uniq
      end

      sig {
        params(current_tag: String).returns(T.nilable(TimestampTag))
      }
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

      sig { returns(T.nilable(TimestampTag)) }
      def latest_timestamp_tag
        @latest_timestamp_tag ||= timestamp_tags.sort.last
      end

      sig { returns(T::Array[TimestampTag]) }
      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      sig { returns(T.self_type) }
      def all
        self
      end

      sig { returns(LocalTags) }
      def local
        @local ||= LocalTags.new(cli, image_url)
      end

      sig { returns(RemoteTags) }
      def remote
        @remote ||= RemoteTags.new(remote_client, image_url)
      end
    end
  end
end
