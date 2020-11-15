---
id: managing-secrets
title: Managing Secrets
sidebar_label: Managing Secrets
slug: /managing-secrets
---

Secrets are defined as any sensitive configuration data your app needs to run. Secrets include things like 3rd-party API keys, usernames, and passwords. Kubernetes provides a special kind of object, appropriately called a `Secret`, to store secrets.

## Rails' Encrypted Credentials

Rails natively provides a way to manage secrets known as the [encrypted credentials](https://edgeguides.rubyonrails.org/security.html#custom-credentials) store. Credentials are encrypted with a master key and stored in config/credentials.yml.enc. Rather than convert this file into a Kubernetes secret, Kuby instead creates a secret that contains only the master key. When your app boots, Kubernetes makes the `RAILS_MASTER_KEY` environment variable available inside the container. Your app can use `Rails.application.credentials` as it normally would without any additional configuration.

During the deploy, Kuby will first attempt to read your master key from the `RAILS_MASTER_KEY` environment variable and fall back to reading the contents of config/master.key. If neither exists, your secrets won't be accessible inside the container. As you'd expect, config/master.key is ignored by git, meaning config/master.key won't exist inside a fresh clone of your codebase. For that reason, make sure you store the master key in a secure location immediately after creating your app with `rails new`. To pass it in during the deploy, try something like this:

```bash
RAILS_MASTER_KEY='abc123' bundle exec kuby -e production deploy
```

## Custom Secrets

For those who would rather not use Rails' encrypted credentials store, Kuby allows adding custom secrets in the form of key/value pairs. These key/value pairs will appear as environment variables inside your running containers.

```ruby
Kuby.define('my-app') do
  environment(:production) do
    plugin(:rails_app) do
      app_secrets do
        data do
          add 'GMAIL_USERNAME', 'foo@bar.com'
          add 'GMAIL_PASSWORD', '123abc'
        end
      end
    end
  end
end
```

**NOTE**: Please don't hard-code secrets into your Kuby config as I have done in the example above. Read them from a file, pass them in as environment variables, or... do something else. The whole point of secrets is to keep them out of your code and therefore out of git. For example, try this instead:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    plugin(:rails_app) do
      app_secrets do
        data do
          add 'GMAIL_USERNAME', ENV['GMAIL_USERNAME']
          add 'GMAIL_PASSWORD', ENV['GMAIL_PASSWORD']
        end
      end
    end
  end
end
```

Then deploy like so:

```bash
GMAIL_USERNAME='foo@bar.com' GMAIL_PASSWORD='abc123' \
  bundle exec kuby -e production deploy
```
