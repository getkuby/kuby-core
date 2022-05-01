---
id: understanding-kubernetes
title: Understanding Kubernetes
sidebar_label: Understanding Kubernetes
slug: /understanding-kubernetes
---

Kuby uses Kubernetes to deploy and manage Rails applications. Kubernetes is a platform that runs container-based workloads like web applications, queuing systems, and more. It's quickly becoming a very common way companies and individuals alike run their applications in the cloud. Because the Kubernetes API works the same way across all hosting providers that offer it, Kuby can deploy and manage applications in myriad cloud environments like Azure, AWS, DigitalOcean, and Linode, without requiring any provider-specific configuration.

## Interacting with your Cluster

You can execute arbitrary kubectl commands via the `kuby` executable, eg:

```bash
bundle exec kuby -e production kubectl -- [command]
```

Kuby deploys your application into a Kubernetes **namespace**. To execute a kubectl command in the context of this namespace, pass the `-N` option:

```bash
bundle exec kuby -e production kubectl -N -- [command]
```

See the following sections for more detail.

## Intro to Kubernetes

Kubernetes is really two separate things: an API layer called the **control plane**, and individual servers called **nodes** that run your containers. Each node runs a special program called the **kubelet** that is responsible for ensuring the right containers are running on the node. If one of the containers crashes, the kubelet restarts it. If the user asks for another instance of the web app, the control plane chooses a node with sufficient capacity and instructs its kubelet to spin up another container in response.

Kubernetes ships with a command-line tool called kubectl (pronounced "kube control" or "kube cuttle") that facilitates making API requests to the control plane. Under the hood, Kuby uses kubectl to deploy resources to your cluster and query it for state.

### Pods

The most granular unit of work in Kubernetes is called a **pod**. There is usually a 1:1 correspondence between pods and containers, i.e. most of the time pods run a single container. Kuby creates one pod for the Rails app, one pod for the Nginx-based static asset server, and three pods for the database (three is the minimum allowed by CockroachDB to maintain high-availability and resiliency).

Use Kuby's `remote status` command to list all the running pods:

```bash
bundle exec kuby -e production remote status
```

### Services

Kubernetes uses **services** to load balance between a group of pods. It's often a good idea to run two or more copies of your application both for resiliency and throughput reasons, the idea being two copies of your app can serve twice as much traffic as one copy. Each copy runs in a separate pod, and a service balances traffic evenly between the pods.

To see the services in your app's namespace, run this command:

```bash
bundle exec kuby -e production kubectl -N -- get services
```

### The Ingress Controller

Kubernetes uses an **ingress controller** to route external traffic into your cluster. The ingress controller is responsible for routing traffic to the correct service (see above). The service then sends the request to one of its constituent pods where your application is running. The response from your application is sent back to the service, then back to the ingress controller, then to the client's browser. Kuby uses the standard Nginx ingress controller.

To see the ingress objects in your app's namespace, run this command:

```bash
bundle exec kuby -e production kubectl -N -- get ingresses
```

### Logs

By default, Kubernetes captures all output sent to the container's STDOUT stream. You can retrieve the most recent logs for a container using the `kubectl logs` command, or easily for your web application by running:

```bash
bundle exec kuby -e production remote logs
```

To get the logs for a non-web pod, first find the name of the pod, then run:

```bash
bundle exec kuby -e production kubectl -- logs <pod name>
```

### Resources

In Kubernetes, everything is a resource. Resources generally have a "kind" (eg. "Service", "Pod", etc), and a unique name. Kubernetes resources are often represented in YAML or JSON format. Here's a simple namespace object represented in YAML:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-production
```

Kubernetes resources are often very complicated. Each kind is [documented](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) extensively on the Kubernetes website.

Kuby defines resources in Ruby code using the [kube-dsl gem](https://github.com/getkuby/kube-dsl) which are serialized to YAML before being deployed into the Kubernetes cluster. Here's the equivalent Ruby code for the namespace above:

```ruby
require 'kube-dsl'

KubeDSL.namespace do
  metadata do
    name 'myapp-production'
  end
end
```
