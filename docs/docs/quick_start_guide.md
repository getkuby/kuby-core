---
id: quick-start-guide
title: Quick Start Guide
sidebar_label: Quick Start Guide
slug: /
---

Getting your Rails app set up to work with Kuby is pretty straightforward. Here's a quick overview of the necessary steps:

1. Install Docker
1. Choose a hosting provider
1. Choose a Docker registry
1. Add the Kuby gems to your bundle
1. Configure Kuby
1. Deploy!

**NOTE**: Kuby is designed to work with Rails 5.2 and up.

## Installing Docker

The easiest way to install Docker for MacOS and Windows is via [Docker Desktop](https://www.docker.com/products/docker-desktop). You will need Docker to build and push the Docker image for your application (described below).

## Choosing a Provider

The first step in deploying your app is to choose a hosting provider. At the time of this writing, Kuby supports [DigitalOcean](https://github.com/getkuby/kuby-digitalocean), [Linode](https://github.com/getkuby/kuby-linode), [Azure](https://github.com/getkuby/kuby-azure), and Amazon's [EKS](https://github.com/getkuby/kuby-eks). Use your provider's dashboard to spin up a Kubernetes cluster. In most cases, this shouldn't involve more than a few button clicks, although for more customizable providers like EKS and Azure you might want to look for specific guides online.

## Choosing a Docker Registry

Kuby uses Docker to package up your application into a Docker _image_. Images are then pushed (i.e. uploaded) to something called a "registry." Registries host Docker images so they can be pulled (i.e. downloaded) by the servers that will eventually run them.

### Docker Hub

There are a number of Docker registries available, some free and some paid. Docker's own offering is called [Docker Hub](https://hub.docker.com/), the de-facto registry for open-source projects and commercial solutions alike. Images hosted on Docker Hub are referred to using an abbreviated URL without a hostname, i.e. `<username>/<repo>`. If you see an image referred to like this, it means it's hosted on Docker Hub.

### Gitlab

Gitlab's Docker registry is a great alternative to Docker Hub. It's free and unlimited. Oh, and a quick note: you don't have to host your code on Gitlab to take advantage of the registry, but they're great for that too.

Images hosted on 3rd-party registries (i.e. not on Docker Hub) are referred to by their full URL. If you choose to use Gitlab's Docker registry, the URL to your Docker image will look like this:

```
registry.gitlab.com/<username>/<repo>
```

**NOTE**: Gitlab's Docker registry requires you to authenticate using a personal or deploy access token instead of your Gitlab password. See their [documentation](https://docs.gitlab.com/ee/user/packages/container_registry/#authenticate-with-the-container-registry) for more information.

### GitHub

GitHub runs a docker registry, available at docker.pkg.github.com. As with Gitlab, you'll need to refer to the registry using the full URL. The URL should be of the format `:username/:repo/:image_name`, so your URL will look something like

```
docker.pkg.github.com/<username>/<repo>/<image-name>
```

You'll also need to get Docker to log in to the registry using a token with the correct access permissions; you can find out more in [the Github package documenation](https://docs.github.com/articles/configuring-docker-for-use-with-github-package-registry/).

## Adding Kuby to your Bundle

Add the kuby-core gem and the corresponding gem for your chosen provider to your Rails application's Gemfile, for example:

```ruby
gem 'kuby-core', '< 1.0'
gem 'kuby-digitalocean', '< 1.0'
```

Kuby only supports the [CockroachDB](https://www.cockroachlabs.com/product/) database. If you choose to let Kuby manage your database, you'll need to add the adapter gem to your Gemfile as well:

```ruby
gem 'activerecord-cockroachdb-adapter'
```

Run `bundle install` to install the gems.

## Configuring Kuby

All Kuby configuration is written in Ruby and lives in a file called kuby.rb in your application's root directory.

### Using the Rails Generator

Rather than follow all the steps below, feel free to make use of Kuby's Rails generator, which will create all the files you need and put them in the right places. Just run

```sh
bundle exec rails generate kuby
```

and follow the prompts.

### Manual Configuration

Kuby configuration is done via a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language). There are two main sections, one for Docker and one for Kubernetes. Put the config into a file called kuby.rb in the root directory of your Rails app.

Here's what a complete config looks like:

```ruby
require 'kuby/digitalocean'

require 'active_support/core_ext'
require 'active_support/encrypted_configuration'

Kuby.define('my-app') do
  app_creds = ActiveSupport::EncryptedConfiguration.new(
    config_path: File.join('config', 'credentials.yml.enc'),
    key_path: File.join('config', 'master.key'),
    env_key: 'RAILS_MASTER_KEY',
    raise_if_missing_key: true
  )

  environment(:production) do
    docker do
      credentials do
        username app_creds[:DOCKER_USERNAME]
        password app_creds[:DOCKER_PASSWORD]
        email app_creds[:DOCKER_EMAIL]
      end

      image_url 'registry.gitlab.com/username/repo'
    end

    kubernetes do
      provider :digitalocean do
        access_token app_creds[:DIGITALOCEAN_ACCESS_TOKEN]
        cluster_id 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
      end

      add_plugin :rails_app do
        hostname 'mywebsite.com'
      end
    end
  end
end
```

Create a Rails initializer at config/initializers/kuby.rb that loads your Kuby config:

```ruby
require 'kuby'
Kuby.load!
```

Finally, modify your database.yml to use the CockroachDB adapter in the production environment:

```yaml
production:
  <<: *default
  adapter: cockroachdb
  database: my_app_production
```

Let's go over this config in detail.

### Deploy Environments

The first line tells Kuby what you want to call your app:

```ruby
Kuby.define('my-app')
```

**NOTE**: The next block loads your Rails credentials file. Since your Rails environment may or may not be loaded when your Kuby config loads, we have to access Rails credentials manually.

The second line defines the _deploy environment_:

```ruby
environment(:production)
```

Deploy environments usually closely mirror your Rails environments. For example, you might create a new Rails environment called "staging" or "preprod" that's used to test production changes before they go live.

If you're a small shop or hobbyist though, chances are the "production" deploy environment is all you need.

### Configuring Docker

Kuby can automatically "dockerize" your application. You just need to tell it where to push images and provide some credentials:

```ruby
docker do
  credentials do
    username app_creds[:DOCKER_USERNAME]
    password app_creds[:DOCKER_PASSWORD]
    email app_creds[:DOCKER_EMAIL]
  end

  image_url 'registry.gitlab.com/username/repo'
end
```

The username, password, and email fields are used to authenticate with the Docker registry that hosts your images. For GitHub and Gitlab, you'll need to create a personal access token instead of using your password. Here are the docs for [Gitlab](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) and here are the docs for [GitHub](https://docs.github.com/articles/configuring-docker-for-use-with-github-package-registry/). The `image_url` field is the full URL to your Docker image, including the registry's domain.

In the example above, the username, password, and email are all provided by Rails' [encrypted credentials](https://guides.rubyonrails.org/v5.2/security.html#custom-credentials) feature. It's important to remember to **NEVER** hard-code sensitive information (like passwords) in your Kuby config or check it into source control (i.e. git). If you'd rather not use encrypted credentials, consider using a tool like [dotenv](https://github.com/bkeepers/dotenv) to automatically load your secrets into environment variables when your app starts (NOTE: don't check the .env file into git either!)

### Configuring Kubernetes

Now that your app can be packaged up into a Docker image, it's time to use Kubernetes to run it. There are two top-level concerns in the Kubernetes section of your Kuby config: providers and plugins.

#### Providers

Each Kubernetes definition must have a provider configured. Providers correspond to the hosting provider you chose earlier. For example, you'll need to add the `:digitalocean` provider to deploy to a managed DigitalOcean Kubernetes cluster.

```ruby
kubernetes do
  provider :digitalocean do
    access_token app_creds[:DIGITALOCEAN_ACCESS_TOKEN]
    cluster_id 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
  end
end
```

Providers can have different config options, so make sure you consult the gem's README for the provider you've chosen.

#### Plugins

Nearly all Kuby's functionality is provided via plugins. For example, simply add the `:rails_app` plugin to get your Rails app ready to deploy:

```ruby
add_plugin :rails_app
```

To indicate your app serves a particular domain name, specify the `hostname` option:

```ruby
add_plugin :rails_app do
  hostname 'mywebsite.com'
end
```

Configuring DNS to point to your Kubernetes cluster is outside the scope of this guide, but all the hosting providers should have tutorials readily available. For example, [here's the one](https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) from DigitalOcean.

#### Database Credentials

You may have noticed our Kuby config doesn't contain any mention of database credentials. That's because Kuby automatically creates a set of TLS certificates for communicating with the database instance. Not only is this technique more secure, it's less configuration to worry about. Win win!

## Deploying

Now that Kuby is configured and your Kubernetes cluster is ready, it's time to deploy!

1. Build the Docker image

    ```sh
    RAILS_MASTER_KEY=<your master key> bundle exec kuby -e production build
    ```
    If your master key is stored in the default location (`config/master.key`), you can run `bundle exec kuby` without setting the `RAILS_MASTER_KEY` variable.

1. Push the Docker image to the container registry

    ```sh
    bundle exec kuby -e production push
    ```

1. Set up your provider

    ```sh
    bundle exec kuby -e production setup
    ```

1. Deploy!

    ```sh
    RAILS_MASTER_KEY=<your master key> bundle exec kuby -e production deploy
    ```
    As above, `RAILS_MASTER_KEY` is only required if your key is not stored at `config/master.key`.
1. Rejoice
