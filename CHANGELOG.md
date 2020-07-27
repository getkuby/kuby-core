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
