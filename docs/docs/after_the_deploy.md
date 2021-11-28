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

NOTE: `--kind` uses the exact match and `--name` accepts regular expressions.

Run an arbitrary kubectl command:

```bash
bundle exec kuby -e production kubectl -- [cmd]
```
