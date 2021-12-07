
# typed: strict

module Kuby
  module Docker
    class AppImage < ::Kuby::Docker::TimestampedImage
      extend T::Sig

      sig {
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

      sig { params(build_args: T::Hash[String, String], docker_args: T::Array[String]).returns(AppImage) }
      def build(build_args = {}, docker_args = [])
        unless ENV.fetch('RAILS_MASTER_KEY', '').empty?
          build_args['RAILS_MASTER_KEY'] = T.must(ENV['RAILS_MASTER_KEY'])
        end

        super(build_args, docker_args)
      end
    end
  end
end
