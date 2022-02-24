# typed: ignore

require 'docker/remote'

module Kuby
  module Docker
    class TimestampStrategy < VersionStrategy
      extend T::Sig

      sig { returns(Image) }
      attr_reader :image

      sig { params(image: Image).void }
      def initialize(image)
        @image = T.let(image, Image)

        @new_version = T.let(@new_version, T.nilable(ImageVersion))
        @current_version = T.let(@current_version, T.nilable(ImageVersion))
        @previous_version = T.let(@previous_version, T.nilable(ImageVersion))

        @remote_client = T.let(@remote_client, T.nilable(::Docker::Remote::Client))
        @local = T.let(@local, T.nilable(LocalTags))
        @remote = T.let(@remote, T.nilable(RemoteTags))
        @docker_cli = T.let(@docker_cli, T.nilable(Docker::CLI))
      end

      sig { returns(ImageVersion) }
      def new_version
        @new_version ||= ImageVersion.new(
          image, TimestampTag.now.to_s, [Kuby::Docker::LATEST_TAG]
        )
      end

      sig { returns(ImageVersion) }
      def current_version
        @current_version ||= begin
          ImageVersion.new(
            image, latest_timestamp_tag.to_s, [Kuby::Docker::LATEST_TAG]
          )
        rescue MissingTagError
          new_version
        end
      end

      sig { params(current_tag: T.nilable(String)).returns(ImageVersion) }
      def previous_version(current_tag = nil)
        @previous_version ||= ImageVersion.new(
          image, previous_timestamp_tag(current_tag).to_s, []
        )
      end

      private

      sig { params(current_tag: T.nilable(String)).returns(TimestampTag) }
      def previous_timestamp_tag(current_tag = nil)
        current_tag = TimestampTag.try_parse(current_tag || latest_timestamp_tag.to_s)
        raise MissingTagError, 'could not find current timestamp tag' unless current_tag

        all_tags = timestamp_tags.sort

        idx = all_tags.index do |tag|
          tag.time == current_tag.time
        end

        idx ||= 0
        raise MissingTagError, 'could not find previous timestamp tag' unless idx > 0

        T.must(all_tags[idx - 1])
      end

      sig { returns(TimestampTag) }
      def latest_timestamp_tag
        tag = timestamp_tags.sort.last
        raise MissingTagError, 'could not find latest timestamp tag' unless tag
        tag
      end

      sig { params(tag: String).returns(T::Boolean) }
      def tag_exists?(tag)
        timestamp_tags.include?(TimestampTag.try_parse(tag))
      end

      sig { returns(::Docker::Remote::Client) }
      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          image.registry_index_host,
          image.image_repo,
          image.credentials.username,
          image.credentials.password
        )
      end

      sig { returns(T::Array[TimestampTag]) }
      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      sig { returns(LocalTags) }
      def local
        @local ||= LocalTags.new(docker_cli, image.image_url)
      end

      sig { returns(RemoteTags) }
      def remote
        @remote ||= RemoteTags.new(remote_client, image.registry_index_host)
      end

      sig { returns(Docker::CLI) }
      def docker_cli
        @docker_cli ||= Docker::CLI.new
      end
    end
  end
end
