---
id: after-the-deploy
title: After the Deploy
sidebar_label: After the Deploy
slug: /after-the-deploy
---

Great, you've deployed your app! Now what?

First of all, you can always ask Kuby what's possible by running

```bash
bundle exec kuby --help
```

Check the status of your deployment by running:

```bash
bundle exec kuby -e production remote status
```

The obvious way to see if your app is working or not is to try to access it over the Internet. If the deploy succeeded (and `kuby remote status` indicates everything's up and running) but your app is erroring out, chances are something is misconfigured. A good place to look when diagnosing issues is your Rails server log. Run the following command to see a live log tail:

```bash
bundle exec kuby -e production remote logs
```

Establish a shell session by running:

```bash
bundle exec kuby -e production remote shell
```

Establish a Rails console session by running:

```bash
bundle exec kuby -e production remote console
```

Establish a database console session by running:

```bash
bundle exec kuby -e production remote dbconsole
```

### Other Useful Commands

Print out all the Dockerfiles:

```bash
bundle exec kuby -e production dockerfiles
```

You can also show a Dockerfile for a particular image (using its identifier):

```bash
bundle exec kuby -e production dockerfiles --only app
```

Print out all your Kubernetes configs:

```bash
bundle exec kuby -e production resources
```

You can also specify Kind and/or Name filters:

```bash
bundle exec kuby -e production resources --kind service --name ".+-(web|rpc)"
```

NOTE: `--kind` filters for an exact match and `--name` accepts regular expressions.

Run an arbitrary kubectl command:

```bash
bundle exec kuby -e production kubectl -- [cmd]
```

Run an arbitrary kubectl command in the app's Kubernetes namespace by passing the `-N` flag:

```bash
bundle exec kuby -e production kubectl -N -- [cmd]
```

### Troubleshooting

The following list is not exhaustive. It mostly contains solutions to issues that have been reported via GitHub.

1. **The TLS certificate for my app's domain name isn't working.**

  TLS certificate issues are most commonly caused by DNS propagation lag. Kuby uses the [cert-manager](https://github.com/cert-manager/cert-manager) operator to automatically request and install TLS certificates from [Let's Encrypt](https://letsencrypt.org/). cert-manager works by creating a special route inside your application that responds to ACME challenges. Let's Encrypt will make a request to this special route and issue the TLS certificate if the response matches what Let's Encrypt expects. This is how Let's Encrypt verifies you actually own the domain name. For this whole dance to work however, Let's Encrypt has to be able to connect to your app. It does so by querying a DNS server. DNS servers map domain names to IP addresses. If you've only just configured the DNS for your domain name within the last 24-48 hours, it's likely DNS information has not propagated (read: been copied) to all the DNS servers around the globe. Often the solution is to simply wait a few hours, although the propagation process can take up to a few days. cert-manager will try periodically to request the certificate, so no additional intervention is usually necessary.

1. **"unable to recognize [url]" during setup or deploy.**

  Often this error indicates your Kubernetes cluster is out-of-date. You'll need to use a version Kuby supports. At the time of this writing, Kuby supports Kubernetes versions 1.20 - 1.23.
