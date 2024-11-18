# typed: strict

require 'docker/remote'

module Kuby
  module Docker
    class TimestampedImage < Image
      # extend T::Sig

      # T::Sig::WithoutRuntime.sig {
      #   params(
      #     dockerfile: T.any(Dockerfile, T.proc.returns(Kuby::Docker::Dockerfile)),
      #     image_url: String,
      #     credentials: Kuby::Docker::Credentials,
      #     registry_index_url_str: T.nilable(String),
      #     main_tag: T.nilable(String),
      #     alias_tags: T::Array[String]
      #   ).void
      # }
      def initialize(dockerfile, image_url, credentials, registry_index_url_str = nil, main_tag = nil, alias_tags = [])
        # @new_version = T.let(@new_version, T.nilable(Image))
        # @current_version = T.let(@current_version, T.nilable(Image))
        # @previous_version = T.let(@previous_version, T.nilable(Image))

        # @remote_client = T.let(@remote_client, T.nilable(::Docker::Remote::Client))
        # @local = T.let(@local, T.nilable(LocalTags))
        # @remote = T.let(@remote, T.nilable(RemoteTags))

        super
      end

      # T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::Image) }
      def new_version
        @new_version ||= duplicate_with_tags(
          TimestampTag.now.to_s, [Kuby::Docker::LATEST_TAG]
        )
      end

      # T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::Image) }
      def current_version
        @current_version ||= begin
          duplicate_with_tags(
            latest_timestamp_tag.to_s, [Kuby::Docker::LATEST_TAG]
          )
        rescue MissingTagError
          new_version
        end
      end

      # T::Sig::WithoutRuntime.sig { params(current_tag: T.nilable(String)).returns(Kuby::Docker::Image) }
      def previous_version(current_tag = nil)
        @previous_version ||= duplicate_with_tags(
          previous_timestamp_tag(current_tag).to_s, []
        )
      end

      # T::Sig::WithoutRuntime.sig { params(current_tag: T.nilable(String)).returns(Kuby::Docker::TimestampTag) }
      def previous_timestamp_tag(current_tag = nil)
        current_tag = TimestampTag.try_parse(current_tag || latest_timestamp_tag.to_s)
        raise MissingTagError, 'could not find current timestamp tag' unless current_tag

        all_tags = timestamp_tags.sort

        idx = all_tags.index do |tag|
          tag.time == current_tag.time
        end

        idx ||= 0
        raise MissingTagError, 'could not find previous timestamp tag' unless idx > 0

        all_tags[idx - 1]
      end

      # T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::TimestampTag) }
      def latest_timestamp_tag
        tag = timestamp_tags.sort.last
        raise MissingTagError, 'could not find latest timestamp tag' unless tag
        tag
      end

      # T::Sig::WithoutRuntime.sig {
      #   params(
      #     build_args: T::Hash[String, String],
      #     docker_args: T::Array[String],
      #     context: T.nilable(String),
      #     cache_from: T.nilable(String)
      #   ).void
      # }
      def build(build_args = {}, docker_args = [], context: nil, cache_from: nil)
        docker_cli.build(
          self,
          build_args: build_args,
          docker_args: docker_args,
          context: context,
          cache_from: cache_from
        )
      end

      # T::Sig::WithoutRuntime.sig { params(tag: String).void }
      def push(tag)
        docker_cli.push(image_url, tag)
      end

      # T::Sig::WithoutRuntime.sig { params(tag: String).void }
      def pull(tag)
        docker_cli.pull(image_url, tag)
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Boolean) }
      def exists?
        return false unless main_tag
        timestamp_tags.include?(TimestampTag.try_parse(main_tag))
      end

      private

      # T::Sig::WithoutRuntime.sig { returns(::Docker::Remote::Client) }
      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          registry_index_host, image_repo, credentials.username, credentials.password,
        )
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Array[Kuby::Docker::TimestampTag]) }
      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      # T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::LocalTags) }
      def local
        @local ||= LocalTags.new(docker_cli, image_url)
      end

      # T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::RemoteTags) }
      def remote
        @remote ||= RemoteTags.new(remote_client, registry_index_host)
      end
    end
  end
end
