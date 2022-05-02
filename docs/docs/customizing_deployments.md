---
id: customizing-deployments
title: Customizing Deployments
sidebar_label: Customizing Deployments
slug: /customizing-deployments
---

Kuby is designed to be beginner-friendly. It requires very little configuration and tries to fall back to smart defaults whenever possible.

However, Kuby is also designed to be highly flexible and configurable should the need arise.

## Providers

A **provider** allows Kuby to communicate with a Kubernetes cluster. Cloud service providers like DigitalOcean, AWS, and Azure, offer hosted Kubernetes solutions that make it very easy to create and manage clusters. There are Kuby provider gems for each of these platforms (and more) that facilitate deploying your application. They handle wrangling the necessary configuration parameters and other trivia.

Providers are configured inside the `kubernetes do ... end` block of your Kuby config:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      provider :linode do
        # Linode-specific configuration options go here.
        # See the README in getkuby/kuby-linode for details.
      end
    end
  end
end
```

Interested in contributing a provider? See the [provider base class](https://github.com/getkuby/kuby-core/blob/ab58f7cc308348ae492a2d37dcf88686d2292917/lib/kuby/kubernetes/provider.rb) for the provider interface.

### Available Provider Gems

Kuby currently offers the following providers, distributed as Rubygems:

* DigitalOcean: [getkuby/kuby-digitalocean](https://github.com/getkuby/kuby-digitalocean)
* Linode: [getkuby/kuby-linode](https://github.com/getkuby/kuby-linode)
* Amazon EKS: [getkuby/kuby-eks](https://github.com/getkuby/kuby-eks)
* Azure AKS: [getkuby/kuby-azure](https://github.com/getkuby/kuby-azure)
* Kind: [getkuby/kuby-kind](https://github.com/getkuby/kuby-kind)

### The Bare Metal Provider

Kuby comes with a provider out of the box for connecting to arbitrary Kubernetes clusters called the "bare metal" provider. Use this provider if the cloud services company you're using isn't supported by Kuby (i.e. there is no provider gem available), or if you're managing your cluster manually in-house. The bare metal provider requires that you already have a kubeconfig file.

:::info
The kubeconfig file (so-called because it's usually stored at ~/.kube/config) is a configuration file used by `kubectl` and other tools to communicate securely with a Kubernetes cluster. For more information, see the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/).
:::

The bare metal provider supports the following configuration options:

* `kubeconfig(String)`: The path to the kubeconfig file.
* `storage_class(String)`: The Kubernetes storage class to use for requesting persistent volume storage. Defaults to "hostpath".

Configure the bare metal provider like so:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      provider :bare_metal do
        kubeconfig '/Users/me/.kube/config'
      end
    end
  end
end
```

## Plugins

Nearly all Kuby's functionality is provided as a series of plugins. Plugins can be added, configured, and removed inside the `kubernetes do ... end` block.

If you read the Getting Started section of this guide, you saw how to add and configure the `:rails_app` plugin. Let's add Sidekiq queuing functionality as another example.

1. First, you'll need to add the [sidekiq](https://github.com/mperham/sidekiq) and [kuby-sidekiq](https://github.com/getkuby/kuby-sidekiq) gems to your Gemfile and run `bundle install`.
1. Next, add `require 'kuby/sidekiq'` to the top of your Kuby config (i.e. in kuby.rb).
1. Add the plugin by calling `add_plugin :sidekiq`.
1. Add a few lines of Ruby code into an initializer to configure your app to use Sidekiq.

```ruby title="kuby.rb"
require 'kuby/sidekiq'

Kuby.define('my-app') do
  environment(:production) do
    add_plugin :sidekiq
  end
end
```

```ruby title="config/initializers/sidekiq.rb"
if Rails.env.production?
  require 'kuby'

  Kuby.load!

  Sidekiq.configure_server do |config|
    config.redis = Kuby.environment.kubernetes.plugin(:sidekiq).connection_params
  end

  Sidekiq.configure_client do |config|
    config.redis = Kuby.environment.kubernetes.plugin(:sidekiq).connection_params
  end
end
```

:::tip
You'll need to run `kuby setup` and then `kuby deploy` again after completing these steps.
:::

The kuby-sidekiq plugin handles all the necessary configuration to stand up an instance of Redis in your cluster, as well as a worker pod for processing background jobs.

Now let's spin up another worker pod by passing a block to `add_plugin`:

```ruby
add_plugin :sidekiq do
  replicas 2
end
```

Running `kuby deploy` again will result in two worker pods.

To create your own plugins, see the [Creating Plugins](./creating-plugins) page in this guide.

### Rake Tasks

As of kuby-core v0.18, plugins can define [Rake](https://github.com/ruby/rake) tasks.

To see a list of all available tasks, run:

```bash
bundle exec kuby -e production plugin rake
```

To run a Rake task, append its name to the command:

```bash
bundle exec kuby -e production plugin rake <task name>
```

## Built-in Plugins

Kuby comes with a set of built-in plugins like the `:rails_app` one we've seen already. The following sections describe these plugins and how to configure them.

Show all the plugins currently configured for the given environment (production in this case) by running:

```bash
bundle exec kuby -e production plugin list
```

To show all the plugins Kuby knows about even if they aren't configured for the given environment, pass the `--all` flag:

```bash
bundle exec kuby -e production plugin list --all
```

### The Rails App Plugin

The Rails app plugin generates all the configuration necessary to run your Rails app in your Kubernetes cluster, and supports the following configuration options.

* `hostname(String)`: The hostname (i.e. domain name) for your app. Something like my-awesome-website.com, etc. Note that you will need to purchase a domain name and configure DNS properly to be able to reach your website.
* `tls_enabled(true | false)`: Whether or not the plugin should attempt to fetch and install a Let's Encrypt TLS certificate for your app. Defaults to `true`.
* `manage_database(true | false)`: Whether or not the plugin should create a CockroachDB instance for your app. Defaults to `true`.
* `replicas(Integer)`: The number of instances of your app to run. Defaults to 1.
* `asset_url(String)`: The URL prefix to your app's static assets. Defaults to /assets.
* `packs_url(String)`: The URL prefix to your app's JavaScript packs (generated by webpack/webpacker). Defaults to /packs.
* `asset_path(String)`: The path on disk where your static assets reside. Defaults to ./public.

For example, to disable TLS certificates, configure the plugin like this:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      plugin :rails_app do
        tls_enabled false
      end
    end
  end
end
```

:::info
The remaining plugins listed below are automatically added and configured by the Rails app plugin, so there's usually no need to configure them on your own.
:::

### The Rails Assets Plugin

The Rails assets plugin creates a separate Kubernetes deployment for serving your app's static assets. A separate static asset server leaves your Rails app free to serve web requests. The plugin uses Nginx, a proven, high-performance web server.

* `asset_url(String)`: The URL prefix to your app's static assets. Defaults to /assets.
* `packs_url(String)`: The URL prefix to your app's JavaScript packs (generated by webpack/webpacker). Defaults to /packs.
* `asset_path(String)`: The path on disk where your static assets reside. Defaults to ./public.

### The Nginx Ingress Plugin

The Nginx ingress plugin is responsible for installing the [ingress-nginx](https://github.com/kubernetes/ingress-nginx) Kubernetes operator. It has only one configuration option that is usually set by the provider.

* `provider(String)`: Sets the provider. Must correspond to one of the available manifests [here](https://github.com/kubernetes/ingress-nginx/tree/controller-v1.1.1/deploy/static/provider). Defaults to using the "cloud" manifest.

### The CRDB Plugin

The CRDB plugin is responsible for starting an instance of [CockroachDB](https://github.com/cockroachdb/cockroach) for the Rails app.

* `add_client_user(username: String)`: Adds an additional user that will be able to connect to the database. A separate certificate will be created and configured for the user.

## Additional Plugins

The Kuby ecosystem features a number of other plugins distributed as Ruby gems.

### The cert-manager Plugin

Repository: [getkuby/kuby-cert-manager](https://github.com/getkuby/kuby-cert-manager)

The cert-manager plugin uses the awesome [cert-manager](https://github.com/jetstack/cert-manager) operator to automatically request and install TLS certificates on your behalf. Behind the scenes, cert-manager uses [Let's Encrypt](https://letsencrypt.org/), a non-profit certificate authority trusted by all the major browsers. You don't need an account to use Let's Encrypt, but you do need an email address. By default, the cert-manager plugin uses the email address you provided as part of your Docker registry credentials. A certificate will be issued for the hostname configured for your Rails app.

Moreover, the cert-manager plugin can be used to create custom public key infrastructures (PKIs). Take a look at the [CRDB plugin](https://github.com/getkuby/kuby-core/blob/ab58f7cc308348ae492a2d37dcf88686d2292917/lib/kuby/plugins/rails_app/crdb/plugin.rb) for an example.

### The Prebundler Plugin

Repository: [getkuby/kuby-prebundler](https://github.com/getkuby/kuby-prebundler)

The Prebundler plugin uses [Prebundler](https://github.com/camertron/prebundler) to dramatically improve the performance of `bundle install`, which can take a long time during Docker builds.

### The Redis Plugin

Repository: [getkuby/kuby-redis](https://github.com/getkuby/kuby-redis)

The Redis plugin uses the [Spotahome Redis operator](https://github.com/spotahome/redis-operator) to stand up Redis instances in your cluster. It is used by the Sidekiq plugin (see below).

### The Sidekiq Plugin

Repository: [getkuby/kuby-sidekiq](https://github.com/getkuby/kuby-sidekiq)

The Sidekiq plugin deploys [Sidekiq](https://github.com/mperham/sidekiq) workers into your cluster for easy background job processing.

### The AnyCable Plugin

Repository: [anycable/kuby-anycable](https://github.com/anycable/kuby-anycable)

The AnyCable plugin allows you to install all the required [AnyCable](https://anycable.io/) components to your Kubernetes cluster.
