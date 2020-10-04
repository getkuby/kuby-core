---
id: development
title: Developing with Kuby [WIP]
sidebar_label: Developing with Kuby [WIP]
slug: /development
---

:::caution
This feature is a work in progress and should be considered experimental.
:::

Kuby ships with a default environment called "development" that is capable of running your application locally using the copy of Kubernetes that comes with [Docker Desktop](https://www.docker.com/products/docker-desktop). Running your app inside a local Kubernetes cluster provides several significant benefits:

1. Your development environment more closely mirrors your production environment, leading to (hopefully) fewer configuration issues, etc.
1. Kuby can automatically start up a database for your app, obviating the need to run one yourself.

## Getting Started

1. If you haven't already, install [Docker Desktop](https://www.docker.com/products/docker-desktop).
1. In Docker Desktop's preferences, click the Kubernetes tab, then check the "Enable Kubernetes" checkbox. It'll take a few minutes to spin up the cluster.
1. Run `bundle exec kuby rails s`. Kuby will prompt you to setup your dev environment.
1. Your Rails app should boot. Visit localhost:3000 in your browser as you normally would.

### Installing Gems

The setup steps above will automatically run `bundle install` to install all your gem dependencies inside Kubernetes. If you add or remove a gem afterwards however, You'll need to run `bundle install` manually:

```bash
bundle exec kuby remote exec -- bundle install
```

## Running Rails/Rake Tasks

TODO

## How Development Works

TODO
