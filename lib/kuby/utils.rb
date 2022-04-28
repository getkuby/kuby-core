module Kuby
  module Utils
    autoload :SemVer, 'kuby/utils/sem_ver'
    autoload :Table,  'kuby/utils/table'
    autoload :Which,  'kuby/utils/which'

    def self.which(*args)
      Which.which(*args)
    end
  end
end
