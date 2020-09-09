module Kuby
  module Docker
    class SetupPhase < Layer
      DEFAULT_WORKING_DIR = '/usr/src/app'.freeze

      attr_accessor :base_image, :working_dir, :rails_env

      def apply_to(dockerfile)
        dockerfile.from(base_image || default_base_image)
        dockerfile.workdir(working_dir || DEFAULT_WORKING_DIR)
        dockerfile.env("RAILS_ENV=#{rails_env || Kuby.env}")
        dockerfile.env("KUBY_ENV=#{Kuby.env}")
        dockerfile.arg('RAILS_MASTER_KEY')
      end

      private

      def default_base_image
        @default_base_image ||= case metadata.distro
          when :debian
            "ruby:#{RUBY_VERSION}"
          when :alpine
            "ruby:#{RUBY_VERSION}-alpine"
          else
            # ERROR
        end
      end
    end
  end
end
