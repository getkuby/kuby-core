# typed: strict

require 'docker/remote'

module Kuby
  module Docker
    class RemoteTags
      # extend T::Sig

      # T::Sig::WithoutRuntime.sig { returns(::Docker::Remote::Client) }
      attr_reader :remote_client

      # T::Sig::WithoutRuntime.sig { returns(String) }
      attr_reader :image_url

      # T::Sig::WithoutRuntime.sig {
      #   params(
      #     remote_client: ::Docker::Remote::Client,
      #     image_url: String
      #   )
      #   .void
      # }
      def initialize(remote_client, image_url)
        @remote_client = remote_client
        @image_url = image_url
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def tags
        remote_client.tags || []
      rescue ::Docker::Remote::UnknownRepoError, ::Docker::Remote::UnauthorizedError, ::Docker::Remote::TooManyRetriesError
        # these can happen if we've never pushed to the repo before
        []
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      def latest_tags
        # not available for remote repos
        []
      end

      # T::Sig::WithoutRuntime.sig { returns(T::Array[Kuby::Docker::TimestampTag]) }
      def timestamp_tags
        tags.map { |t| TimestampTag.try_parse(t) }.compact
      end
    end
  end
end
