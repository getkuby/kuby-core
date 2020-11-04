# typed: strict

require 'uri'

module Kuby
  module Docker
    class Metadata
      extend T::Sig

      DEFAULT_DISTRO = :debian
      LATEST_TAG = T.let('latest'.freeze, String)

      sig { params(image_url: String).void }
      attr_writer :image_url

      sig { returns(Environment) }
      attr_reader :environment

      sig { params(environment: Environment).void }
      def initialize(environment)
        @environment = environment
        @tags = T.let([], T::Array[String])

        @image_url = T.let(@image_url, T.nilable(String))
        @image_host = T.let(@image_host, T.nilable(String))
        @image_hostname = T.let(@image_hostname, T.nilable(String))
        @image_repo = T.let(@image_repo, T.nilable(String))
        @distro = T.let(@distro, T.nilable(Symbol))
        @full_image_uri = T.let(@full_image_uri, T.nilable(DockerURI))
        @default_image_url = T.let(@default_image_url, T.nilable(String))
        @default_tags = T.let(@default_tags, T.nilable(T::Array[String]))
      end

      sig { returns(String) }
      def image_url
        @image_url || default_image_url
      end

      sig { returns(String) }
      def image_host
        @image_host ||= full_image_uri.host
      end

      sig { returns(String) }
      def image_repo
        @image_repo ||= full_image_uri.path
      end

      sig { returns(T::Array[String]) }
      def tags
        @tags.empty? ? default_tags : @tags
      end

      sig { returns(Symbol) }
      def distro
        @distro || DEFAULT_DISTRO
      end

      sig { params(distro_name: Symbol).void }
      def distro=(distro_name)
        @distro = distro_name
      end

      private

      sig { returns(DockerURI) }
      def full_image_uri
        @full_image_uri ||= DockerURI.parse(image_url)
      end

      sig { returns(String) }
      def default_image_url
        # assuming dockerhub by not specifying full url
        @default_image_url ||= environment.app_name.downcase
      end

      sig { returns(T::Array[String]) }
      def default_tags
        @default_tags ||= [
          TimestampTag.new(Time.now).to_s, LATEST_TAG
        ]
      end
    end
  end
end
