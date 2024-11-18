
# typed: strict

module Kuby
  module Docker
    class AppImage < ::Kuby::Docker::TimestampedImage
      extend T::Sig

      T::Sig::WithoutRuntime.sig {
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          registry_index_url: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      }
      def initialize(dockerfile, image_url, credentials, registry_index_url = nil, main_tag = nil, alias_tags = [])
        super
        @identifier = "app"
      end
    end
  end
end
