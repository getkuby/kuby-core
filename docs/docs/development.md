---
id: development
title: Developing with Kuby
sidebar_label: Developing with Kuby
slug: /development
---

Kuby used to ship with a default environment called "development" that was capable of running your application locally using the copy of Kubernetes that comes with [Docker Desktop](https://www.docker.com/products/docker-desktop).

Unfortunately it proved to be too difficult to maintain, so support was removed in version 0.12.0.

## Testing with Kind

While Kuby doesn't support developing your application inside Kubernetes, it does support deploying it to a local Kubernetes cluster for testing purposes using [Kind](https://kind.sigs.k8s.io/).

Kind is a tool that can easily create ephemeral Kubernetes clusters on-the-fly. The [kuby-kind](https://github.com/getkuby/kuby-kind) gem features a Kuby provider that makes it a snap to deploy to a local cluster.

### Configuring the Kind Provider

1. First, add the kuby-kind gem to your Gemfile and run `bundle install`.
1. Create a development environment and configure Kind as the provider.
  ```ruby
  require 'kuby/kind'

  Kuby.define('my-app') do
    environment(:development) do
      kubernetes do
        provider :kind
      end
    end
  end
  ```
1. Run setup
  ```bash
  bundle exec kuby -e development setup
  ```
1. Deploy
  ```bash
  bundle exec kuby -e development deploy
  ```

### Sharing Configuration Between Environments

To keep the code focused, the `docker do ... end` section was omitted from the example above. Let's look at a more complete example.

We could duplicate configuration from the production environment, but it would be nice if we could share it instead. Configuration sharing can be done with Ruby lambas and `instance_exec`. For example:

```ruby
Kuby.define('my-app') do
  shared = -> do
    docker do
      image_url 'registry.gitlab.com/username/repo'

      credentials do
        # ...
      end
    end
  end

  environment(:production) do
    instance_exec(&shared)

    kubernetes do
      # production provider
      provider :linode do
        # ...
      end
    end
  end

  environment(:development) do
    instance_exec(&shared)

    kubernetes do
      # development provider
      provider :kind
    end
  end
end
```

All the Docker config is defined in one place and applied to each environment.
