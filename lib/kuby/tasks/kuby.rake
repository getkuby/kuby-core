require 'shellwords'

namespace :kuby do
  def tasks
    Kuby.load!
    @tasks ||= Kuby::Tasks.new(Kuby.environment)
  end

  task :dockerfile do
    tasks.print_dockerfile
  end

  task :build do
    tasks.build
  end

  task :run do
    tasks.run
  end

  task :push do
    tasks.push
  end

  task :resources do
    tasks.print_resources
  end

  task :kubectl, [:cmd] do |_, args|
    tasks.kubectl(Shellwords.shellsplit(args[:cmd]))
  end

  task :deploy do
    tasks.deploy
  end

  task :rollback do
    tasks.rollback
  end

  task :kubeconfig do
    tasks.print_kubeconfig
  end

  task :setup do
    tasks.setup
  end

  namespace :remote do
    task :logs do
      tasks.remote_logs
    end

    task :status do
      tasks.remote_status
    end

    task :shell do
      tasks.remote_shell
    end

    task :console do
      tasks.remote_console
    end

    task :dbconsole do
      tasks.remote_dbconsole
    end
  end
end
