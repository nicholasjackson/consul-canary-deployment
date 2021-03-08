---
id: index
title: Canary Deployments with Flagger and Consul Service Mesh
sidebar_label: Introduction
---

This example shows how you can do Canary Deployments in Consul Service Mesh
on Kubernetes.

## Add the Consul config

```shell
kubectl apply -f ./consul-config.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

## Add the Flagger config

```shell
kubectl apply -f ./flagger.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

## Add the Grafana dashboard

```shell
kubectl apply -f ./dashboard.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

## Setup the application

```shell
kubectl apply -f ./web.yaml -f ./api.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

## Add some automated load generation

```shell
kubectl apply -f ./load-generator.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

## View the dashboard in Grafana

If you look at the dashboard you will see the requests to the Web service and also the upstream calls to the API service.

**User:** admin  
**Pass:** admin

**Link:**
[http://localhost:8080/d/irtYjefGk/canary?orgId=1&refresh=10s](http://localhost:8080/d/irtYjefGk/canary?orgId=1&refresh=10s)

## Modify the API

```shell
kubectl apply -f ./api_v2.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

If you look at Consul you will see that there are now 3 more instances

[http://localhost:8500/ui/dc1/services/api/instances](http://localhost:8500/ui/dc1/services/api/instances)

Flagger will automatically create a service splitter and start sending a small percentage of traffic to the new instances.


```shell
consul config read -kind service-splitter -name api
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

You will also start to see the traffic become distributed between the canary and the primary, assuming it succeedes 
flagger will promote the canary and remove the old version.

[http://localhost:8080/d/irtYjefGk/canary?orgId=1&refresh=10s](http://localhost:8080/d/irtYjefGk/canary?orgId=1&refresh=10s)