require 'shellwords'

namespace :kuby do
  def tasks
    @tasks ||= Kuby::Tasks.new(Kuby.definition)
  end

  task dockerfile: :environment do
    tasks.print_dockerfile
  end

  task build: :environment do
    tasks.build
  end

  task run: :environment do
    tasks.run
  end

  task push: :environment do
    tasks.push
  end

  task resources: :environment do
    tasks.print_resources
  end

  task :kubectl, [:cmd] => [:environment] do |_, args|
    tasks.kubectl(Shellwords.shellsplit(args[:cmd]))
  end

  task deploy: :environment do
    Kuby.definition.kubernetes.deploy
  end

  task rollback: :environment do
    Kuby.definition.kubernetes.rollback
  end

  task kubeconfig: :environment do
    tasks.print_kubeconfig
  end

  task setup: :environment do
    Kuby.definition.kubernetes.setup
  end

  namespace :remote do
    task logs: :environment do
      tasks.remote_logs
    end

    task status: :environment do
      tasks.remote_status
    end

    task shell: :environment do
      tasks.remote_shell
    end

    task console: :environment do
      tasks.remote_console
    end

    task dbconsole: :environment do
      tasks.remote_dbconsole
    end
  end
end
