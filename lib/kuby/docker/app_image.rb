
# typed: strict

module Kuby
  module Docker
    class AppImage < ::Kuby::Docker::TimestampedImage
      extend T::Sig

      sig { params(build_args: T::Hash[String, String], args: T::Array[String]).returns(AppImage) }
      def build(build_args = {}, args = [])
        unless ENV.fetch('RAILS_MASTER_KEY', '').empty?
          build_args['RAILS_MASTER_KEY'] = T.must(ENV['RAILS_MASTER_KEY'])
        end

        super(build_args, args)
      end
    end
  end
end
