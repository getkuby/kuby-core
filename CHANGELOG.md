## 0.18.0
* Add the ability to specify your app's root directory.
  - Call `app_root <path>` inside the `docker` section of your Kuby config file.
  - Necessary for use-cases like apps living inside gem repos, etc.
* Add `:app_phase` to set of Docker build phases.
  - Allows easily setting environment variables.
  - Sets the working directory to the app root if the app's root directory has been set via the `app_root` feature described above.
* Upgrade to Nginx ingress controller v1.1.1.
  - Necessary to support Kind, the local Kubernetes cluster tool (see the kuby-kind gem).
* Run `bundle lock` before installing gem dependencies.
* Fix bug causing errors when certain container registries return a 401 if the repo doesn't exist yet.
  - I'm looking at you, Azure.
* Don't fail to deploy if the app doesn't use Active Record.
* Fix git merge issue causing no output when running `kuby dockerfiles`.
* Upgrade integration tests to Kubernetes 1.23.
  - This upgrade is incompatible with the version of KubeDB we're currently using.
  - KubeDB has been replaced with the CockroachDB operator. Kuby will no longer support KubeDB after this release.
* Add ability to deploy resources into more than one namespace.
* Remove support for MySQL and Postgres in favor of CockroachDB.
  - KubeDB has moved to an incompatible licensing model and Kuby can no longer use it.
  - CockroachDB is now the only managed database offering (aside from SQLite) for the following reasons:
    - CRDB is cloud-native, i.e. is designed to be run on cloud platforms like Kubernetes.
    - CRDB can be easily upgraded in-place while both MySQL and Postgres demand a much more manual, error-prone upgrade process that proved very difficult to automate.
    - CRDB is Postgres wire-compatible, meaning those who use Postgres (and I believe that accounts for the majority of Rails devs) will hardly be impacted by this change at all. While CRDB is not feature-by-feature compatible with Postgres, the differences are unlikely to be important to the average Rails app.
* Use SSL certificates instead of usernames and passwords for database authentication.
  - This is the preferred way to communicate with instances of CockroachDB (also supported by Postgres).
  - Kuby uses cert-manager to establish a custom PKI for database interactions.
  - The Rails generator now entirely omits the database configuration section, making config simpler.
* Avoid failing on first deploy.
  - Previous versions of Kuby did not wait for the database to spin up before attempting to start the Rails app, which resulted in what appeared to be a failed deploy. Kubernetes would eventually sort everything out, but it made for a less than ideal developer experience.
  - The `create_unless_exists` rake task has been superceded by the `bootstrap` rake task, which is run in an init container whenever the app boots. It is responsible for ensuring the database server is reachable and creating any users defined in the Kuby config.
* Add the ability for plugins to define their own set of rake tasks.
  - These are runnable via the CLI.
* Add the ability for plugins to define a `#remove` routine, which is meant to do the opposite of whatever `#setup` does.
  - It is now also possible to run a plugin's remove routine from the CLI.
* Add the ability for plugins to depend on things like Kubernetes and Helm.
  - Uses semantic versioning and compares required versions to current versions.
* Avoid using the `which` command to find executables on the current PATH.
  - `which` has been deprecated in at least one Linux distro (Debian), perhaps others.
  - Use `Kuby::Utils.which` instead.
* Support Rails 7.
  - Don't run `yarn install` if there's no package.json.
* Automatically cache Docker builds from the latest image, should it exist.

## 0.17.1
* Allow storage class to be customized when using the built-in bare metal provider.
* Fix a bug where the assets image would be built using the previous app image instead of the current one.
* Centralize the lookup of the Rails master key (not user-facing).
* Add descriptions to numerous CLI commands and their arguments.
* CLI now accepts multiple `--only` flags passed to subcommands like `build`, `push`, etc.
* Allow running setup steps for individual plugins.

## 0.16.1
* Fix a few bugs caused by leaving `continue-on-error: true` in the GitHub actions config 🤦
  - Docker builds would fail if no previous images existed in the registry.
  - The assets image would fail to build because `RAILS_MASTER_KEY` was not propagated correctly.
* Use the kuby-prebundler gem in the integration tests instead of a custom layer.

## 0.16.0
* Allow Bundler executable to be customized.
  - Main use-case is to allow adding in the Prebundler plugin, https://github.com/getkuby/kuby-prebundler.
* Print error message and exit on missing Docker build args.
  - Ignore with `--ignore-missing-args`.

## 0.15.0
* Add an extra parameter to the Docker spec for specifying the URL of the Docker registry index.
  - In most cases, the registry and registry index URLs will be the same. However Docker Hub, the default registry, uses index.docker.io for API requests (catalog, tags, etc) but only allows pushes to docker.io.
* Add config/master.key to the .dockerignore created by the Rails generator.
  - This was an unfortunate oversight, but such are the perils of using pre-1.0 software.
* Print an error message if building images on non-x86 hardware.
  - People with M1 Macs are running into mismatches between their laptop's arch and the arch of their hosting provider's hardware. The error message asks you to explicitly pass the `--platform` flag to Docker.
  - We may need to revisit this in the future if ARM processors become more popular.

## 0.14.0
* Make RAILS_MASTER_KEY available in the assets image (@palkan, #63)
* Allow specifying custom docker build options via CLI (@palkan, #65)

## 0.13.0
* Fix handling rails/rake options in remote exec (@palkan, #60)
* Add `bundler_phase.gemfiles(*paths)` to allow adding additional gemfiles (@palkan, #61)

## 0.12.0
* Fix issue causing volume mount errors when k8s tries to schedule asset pods on multiple nodes (fixes #42).
  - Persistent volumes can only be mounted on a single physical node.
  - Kuby now creates a separate assets image powered by nginx.
  - Ingress routes requests to either the Rails service or assets service depending on the URL (i.e. /assets).
  - Since the ingress layer is now essential, the Docker Desktop provider no longer deletes ingresses or monkeys with service objects. You'll have to either 1) add an entry for your hostname to your hosts file, or 2) set the `Host` header when making requests to your app.
* Plugins can now specify additional Dockerfiles to build during `kuby build`.
* Switch from TravisCI to Github Actions.
* Remove support for development environments.
  - Proved to be too difficult to maintain.
  - Kuby is a _deployment_ tool anyway, not a dev tool.
  - Maybe we can turn the dev stuff into a gem at some point.
* Refactor Docker image logic.
  - Introduced the `Image` class and friends.
  - Deleted the `Kuby::Docker::Metadata` class.
* Add missing git dependency to Alpine distro.
* Add a bare metal provider (fixes #10).

## 0.11.16
* Fix yarn phase
  - Apparently you have to copy at least one file, TIL.

## 0.11.15
* Copy over .npmrc and .yarnrc before running yarn install.

## 0.11.14
* Don't include port in image host for registry secrets (no idea why)

## 0.11.13
* Include port in image host.

## 0.11.12
* Revamp Docker URL parsing
  - Docker URLs shouldn't have a scheme.

## 0.11.11
* Add support for a Docker registry running on localhost.
  - Correctly parse and handle URLs with specific ports.
  - Only perform a Docker login if a username is provided.

## 0.11.10
* Fix spelling in error message.

## 0.11.9
* Use correct Docker Hub registry URL (index.docker.io).

## 0.11.8
* Alias Rails `config_map` to `env`.

## 0.11.7
* Properly namespace constant lookup for `Kubernetes::MissingPluginError`.
* Add missing `#storage` method for Postgres plugin.

## 0.11.6
* Fix Rails generator.
  - Causing `undefined method 'module_parent_name'`. Apparently `module_parent_name` wasn't introduced until Rails 6.

## 0.11.5
* Raise friendlier error when attempting to add Docker credentials in the development environment.
* Raise friendlier error when attempting to set a username and password for SQLite databases.

## 0.11.4
* Fix bug causing crash when running CLI commands.
  - Turns out was caused by adding a Sorbet type annotation inside an anonymous singleton class and forgetting to extend `T::Sig`. Thanks @lazyatom!

## 0.11.3
* I've gone back and forth a few times on this, but I decided to put the initializer code back into the Rails generator.

## 0.11.2
* Attempt to auto-require the requested provider if it isn't registered.
* Adjust error message when provider can't be found to include reminder to add a require statement.

## 0.11.1
* Use integers for ports instead of strings to appease Kubernetes.

## 0.11.0
* Defer evaluation of database config until after Kuby has been configured.
  - The issue that prompted this was that the `database` block was being evaluated before the Rails root had been set via `root`. Kuby couldn't find database.yml in a non-standard location and blew up with an error.
* Fix tests broken in 0.10.1.
* Set up Travis CI builds.
* Add a few tests for custom build phases.
* Add the `Environment#configured?` method that will return `true` if Kuby has been configured and `false` if configuration hasn't happened or is in progress.
* Add sorbet typedefs for some classes.
* Fix issue in Rails generator (hadn't been updated with new `environment` block).
* Add kuby-core.rb so Bundler setup works for Kuby without having to add a Rails initializer.

## 0.10.1
* Fix bug causing some `rails` and `rake` commands to not be executed.
* Fix issue restricting Docker CLI output.

## 0.10.0
* Set default database user and password in dev environment.
* Add ability to run rake tasks in dev environment.
* Disallow running rails and rake tasks in non-dev environments.
* Don't run database config through ERB.
  - Rails env often isn't loaded, so ERB rendering can blow up with `NoMethodError`s, etc.
  - All we really need to know is what database engine to stand up.
* Require database user/password to be added manually to Kuby config.

## 0.9.1
* Run dev setup when asked to.
  - Bug caused dev setup to be skipped even when requested.
* Deployer should be tolerant of missing namespace.

## 0.9.0
* Add support for developing your app using a local Kubernetes cluster.
  - Includes a default `:development` Kuby environment.
* Remove rake tasks in favor of a `kuby` executable powered by [GLI](https://github.com/davetron5000/gli).
* Rename the `minikube` provider to `docker_desktop`, which is more accurate.
* Add more tests.
* Avoid running commands inside pods that aren't running or that are marked for deletion (#15).
* Pass `RAILS_MASTER_KEY` to Docker build (#14).
* Add `kuby remote restart` command for manually restarting Rails pods.
* Automatically restart Rails pods if deploy doesn't change the Docker image URL (#11).

## 0.8.1
* Fix database config rewriter task.
  - Broke with refactoring of database config code.
* More correctly parse Docker image URLs.
  - It can be challenging to identify the hostname in image URLs because 1) the host can be omitted, and 2) the scheme is often omitted.
  - The new strategy is to look for a "." in the first segment of the URL if there is no scheme.  It's not bulletproof but is better than what we had before, which was to assume the first segment was the host. Eg. for an image URL like camertron/foo, we would identify the host as "camertron."
* Add a number of tests and a Rails dummy app in spec/.

## 0.8.0
* Upgrade to Krane >= 1.1.4, < 2.0.
* Remove Krane monkeypatch in ext/.
* Implement a Rails static asset server.
* Move plugins from `Kuby::Kubernetes` namespace to `Kuby` namespace.
  - This is to eventually enable plugins to modify the Dockerfile and introduce additional Dockerfiles (i.e. to enable a development mode, etc).
* Pass `Environment` instead of `Definition` instances around.
  - Providers, plugins, etc all take `Definition` instances. `Definition#kubernetes`, for example, returns the Kubernetes spec for the `Environment` specified by `KUBY_ENV` (or the first env defined if `KUBY_ENV` is not set). This is a problem for Kuby configs that specify multiple environments, and causes plugins to make changes to the default environment instead of the one they've been specifically added to. For example, if the `:production` env is defined first, the `:development` env still gets a cluster issuer from cert-manager even though `enable_tls` is set to `false`.

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
