module Kuby
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path(File.join('tasks', 'kuby.rake'), __dir__)
    end
  end
end
