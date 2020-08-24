module Kuby
  module Plugins
    module RailsApp
      autoload :AssetCopyTask,   'kuby/plugins/rails_app/asset_copy_task'
      autoload :Assets,          'kuby/plugins/rails_app/assets'
      autoload :Database,        'kuby/plugins/rails_app/database'
      autoload :MySQL,           'kuby/plugins/rails_app/mysql'
      autoload :Plugin,          'kuby/plugins/rails_app/plugin'
      autoload :Postgres,        'kuby/plugins/rails_app/postgres'
      autoload :RewriteDbConfig, 'kuby/plugins/rails_app/rewrite_db_config'
      autoload :Sqlite,          'kuby/plugins/rails_app/sqlite'
    end
  end
end

Kuby.register_plugin(:rails_assets, Kuby::Plugins::RailsApp::Assets)

load File.expand_path(File.join('rails_app', 'tasks.rake'), __dir__)
