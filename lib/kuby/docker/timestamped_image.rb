# typed: strict

require 'docker/remote'

module Kuby
  module Docker
    class TimestampedImage < Image
      extend T::Sig

      sig {
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          registry_host_url: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      }
      def initialize(dockerfile, image_url, credentials, registry_host_url = nil, main_tag = nil, alias_tags = [])
        @new_version = T.let(@new_version, T.nilable(Image))
        @current_version = T.let(@current_version, T.nilable(Image))
        @previous_version = T.let(@previous_version, T.nilable(Image))

        @remote_client = T.let(@remote_client, T.nilable(::Docker::Remote::Client))
        @local = T.let(@local, T.nilable(LocalTags))
        @remote = T.let(@remote, T.nilable(RemoteTags))

        super
      end

      sig { returns(Image) }
      def new_version
        @new_version ||= duplicate_with_tags(
          TimestampTag.new(Time.now).to_s, [Kuby::Docker::LATEST_TAG]
        )
      end

      sig { returns(Image) }
      def current_version
        @current_version ||= duplicate_with_tags(
          latest_timestamp_tag.to_s, [Kuby::Docker::LATEST_TAG]
        )
      end

      sig { params(current_tag: T.nilable(String)).returns(Image) }
      def previous_version(current_tag = nil)
        @previous_version ||= duplicate_with_tags(
          previous_timestamp_tag(current_tag).to_s, []
        )
      end

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

      sig { params(build_args: T::Hash[String, String], docker_args: T::Array[String]).void }
      def build(build_args = {}, docker_args = [])
        docker_cli.build(new_version, build_args: build_args, docker_args: docker_args)
        @current_version = new_version
        @new_version = nil
      end

      sig { params(tag: String).void }
      def push(tag)
        docker_cli.push(image_url, tag)
      end

      private

      sig { returns(::Docker::Remote::Client) }
      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          registry_index_host, image_repo, credentials.username, credentials.password,
        )
      end

      sig { returns(T::Array[TimestampTag]) }
      def timestamp_tags
        (local.timestamp_tags + remote.timestamp_tags).uniq
      end

      sig { returns(LocalTags) }
      def local
        @local ||= LocalTags.new(docker_cli, image_url)
      end

      sig { returns(RemoteTags) }
      def remote
        @remote ||= RemoteTags.new(remote_client, registry_index_host)
      end
    end
  end
end
