---
id: data-stores
title: Managing Data Stores
sidebar_label: Managing Data Stores
slug: /data-stores
---

Kuby uses the excellent [KubeDB](https://kubedb.com/) project to stand up databases using Kubernetes. It does so by inspecting your Rails app's database configuration. In other words, without any additional configuration, Kuby will automatically create a database using the same engine and login credentials you've defined in config/database.yml.

## Migrations

Migrations are run automatically on every deploy.

## Increasing Storage

Kuby will instruct your database engine to persist data using whatever form of block (i.e. permanent) storage your provider supports. By default, Kuby asks for 10gb of storage space. If you need more, try this:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      plugin :rails_app do
        database do
          storage '20Gi'
        end
      end
    end
  end
end
```

If you've already deployed and started writing to your database, be careful when changing the amount of requested storage. Consult your provider's documentation for information regarding how to safely resize persistent volumes. Most providers can do so in-place and without requiring a restart or volume reattachment. Depending on what the provider does under the covers, changing the volume size can be a risky operation - check the docs first.

## Using a Managed Database

KubeDB is a fantastic, production-grade offering, but if the thought of running a database in Kubernetes scares you, you're not alone. Many developers prefer to use a managed database hosted and maintained by a cloud provider. You can tell Kuby to not manage the database like so:

```ruby
Kuby.define('my-app') do
  environment(:production) do
    kubernetes do
      plugin :rails_app do
        manage_database false
      end
    end
  end
end
```
