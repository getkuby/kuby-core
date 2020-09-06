## Kuby

Deploy your Rails app the easy way.

## What is Kuby?

At its core, Kuby is a set of tools and smart defaults that encapsulate and codify years of established best-practices around deploying webapps, reducing the amount of time required to take your Rails project from an app that runs on your computer to an app that runs on the Internet.

Under the hood, Kuby leverages the power of Docker and Kubernetes. It tries to make these technologies accessible to the average Rails dev without requiring a devops black belt.

## Why Kuby?

Kuby embraces the same convention-over-configuration approach that Rails does. It aims to reduce the cognitive overhead associated with learning a bunch of ops tools to get your app onto the internet. In other words, Kuby does a whole lot for you. Specifically, it:

* leverages Docker and Kubernetes, industry-leading infrastructure tools.
* automatically configures your app with a TLS certificate from [LetsEncrypt](https://letsencrypt.org/).
* automatically spins up a database instance based on what's in your database.yml.
* runs a separate server for your static assets.
* features a powerful plugin system that allows, for example, easy [Sidekiq integration](https://github.com/get-kuby/kuby-sidekiq).

## Getting Started

See the [Quick Start Guide](https://github.com/getkuby/kuby-core/wiki/Quick-Start-Guide)

## More Info

See the [wiki](https://github.com/getkuby/kuby-core/wiki).

## Running Tests

`bundle exec rspec` should do the trick. Test coverage is very minimal at the moment, however.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
