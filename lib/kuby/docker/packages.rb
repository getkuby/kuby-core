module Kuby
  module Docker
    module Packages
      autoload :ManagedPackage, 'kuby/docker/packages/managed_package'
      autoload :Nodejs,         'kuby/docker/packages/nodejs'
      autoload :Package,        'kuby/docker/packages/package'
      autoload :Yarn,           'kuby/docker/packages/yarn'
    end
  end
end
