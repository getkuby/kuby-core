require 'rake'

namespace :kuby do
  namespace :rails_app do
    namespace :db do
      task :rewrite_config do
        Kuby.load!

        config_file = File.join(Kuby.environment.kubernetes.plugin(:rails_app).root, 'config', 'database.yml')

        if rails_app = Kuby.environment.kubernetes.plugin(:rails_app)
          database = rails_app.database

          if database.plugin.respond_to?(:rewritten_configs)
            File.write(config_file, YAML.dump(database.plugin.rewritten_configs))
            Kuby.logger.info("Wrote #{config_file}")
          end
        end
      end

      task :bootstrap do
        Kuby.load!

        if rails_app = Kuby.environment.kubernetes.plugin(:rails_app)
          if database = rails_app.database
            database.plugin.bootstrap
          end
        end
      end
    end

    namespace :assets do
      task :copy do
        Kuby.load!

        if assets = Kuby.environment.kubernetes.plugin(:rails_assets)
          assets.copy_task.run
        end
      end
    end
  end
end
