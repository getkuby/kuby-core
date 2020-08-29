## NEXT
* Upgrade to Krane >= 1.1.4, < 2.0.
* Remove Krane monkeypatch in ext/.
* Implement a Rails static asset server.
* Move plugins from `Kuby::Kubernetes` namespace to `Kuby` namespace.
  - This is to eventually enable plugins to modify the Dockerfile and introduce additional Dockerfiles (i.e. to enable a development mode, etc).

## 0.7.2
* Fix issue causing `Kuby.environment(...)` to raise an `UndefinedEnvironmentError` for existing environments.

## 0.7.1
* Fix timestamp tag parsing regression caused by adding anchor tags to the regex.
  - Instead, let's rely on `strptime` and return `nil` if it throws an `ArgumentError`.

## 0.7.0
* Automatically perform `docker login` if not already logged into the Docker registry.
* Fix timestamp tag parsing issue causing deploy to fail with no available tags.
  - Issue turned out to be ignoring the month of October in the validation regex.

## 0.6.1
* Fix issue causing database.yml to not be rewritten to point at correct database host.

## 0.6.0
* Don't load the Rails environment when running Kuby's rake tasks.
  - Kuby's gems are still part of the bundle, but config has been moved out of the initializer and into kuby.rb in the Rails root directory.
  - Internal classes no longer retain a reference to `Rails.application`.
  - Kuby config now requires `environment` blocks:
      ```ruby
      Kuby.define('my-app') do
        environment(:production) do
          ...
        end

        environment(:staging) do
          ...
        end
      end
      ```
* Fix `MissingDistroError` caused by not setting a default distro.
* Create a .dockerignore file when running the Rails generator.
* Add ability to insert inline Docker layers without having to create a separate class, eg:
    ```ruby
    insert :hello, before: :bundler_phase do |dockerfile|
      dockerfile.run('echo "hello, world"')
    end
    ```
* Add Postgres database support.
* Don't install sqlite libs by default.
* Modify Rails generator
  - Require kuby and load config safely.
  - Provide manual access to credentials via `ActiveSupport::EncryptedConfiguration`, which is necessary now that our rake tasks don't load the Rails environment.
* Add a convenience method for requesting the amount of block storage for the database.
* Add the ability to entirely disable database management via `manage_database false`.
* Avoid deploying nginx-ingress if it's already deployed.
* Add rake task for running arbitrary `kubectl` commands.

## 0.5.0
* Fix Rails generators issue causing crash at startup.
* Add rake task to run arbitrary kubectl commands.

## 0.4.0
* Introduce simple managed package.
* Refactor deploy task into its own class.

## 0.3.0
* Fix Krane issue causing incorrect constant lookup and therefore deploy failures.
  - See: https://github.com/Shopify/krane/pull/720
  - Fixed via monkeypatch in lib/ext/krane/kubernetes_resource.rb
* Move Docker timestamp tag logic into the `Tags` class.
* Refactor Docker timestamp tag logic.
* Change deployment names so they're more descriptive of the role (i.e. web, worker, etc)
  - Rails app deployment changes from [app_name]-deployment to [app_name]-web.
  - Database deployment changes from [app_name]-[environment]-[adapter] to [app-name]-web-[adapter].
* Add shortcut for specifying number of Rails app replicas.
* Move registry secret from the `rails_app` plugin to the Kubernetes spec.
* Fix rollback functionality.

## 0.2.0
* Move Kubernetes CLI error classes into kubernetes-cli gem.
* Update README to indicate Kuby supports Rails 5.1 and up.
* Depend on railties >= 5.1.

## 0.1.0
* Birthday!
