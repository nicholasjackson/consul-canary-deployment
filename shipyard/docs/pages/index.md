---
id: index
title: Canary Deployments with Flagger and Consul Service Mesh
sidebar_label: Introduction
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Blah blah two tier application

## Setup

To setup the required software for this example please follow one of the following guides:

* [Manual Setup](./manual_setup/README.md)
* [GKE Terraform](./terraform/README.md)
* [Local Setup with Docker](./shipyard/README.md)


## Configuring the application

After installing the cluster and required software you can then install the application. To run the canary deployment demo
you need to configure the following components:

* Consul CRDs for Service Mesh
* Flagger configuration
* Grafana Dashboard
* Load generator
* Application Deployment

### Consul CRDs for Service Mesh

Flagger will controll the traffic splitting however for this to work additional configuration needs to be added 
to Consul.

#### ServiceDefaults

First are the `ServiceDefaults`, this configuration informs Consul that the services `web` and `api` are 
`HTTP` services. Setting the protocol for the service changes the way that the service mesh emits metrics.
Using the HTTP protocol we will be able to see metrics related to the HTTP requests and responses including status codes.
Flagger uses this information to determine the health of a canary.

```yaml title="/app/consul-config.yaml"
---
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: web
spec:
  protocol: http

---
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: api
spec:
  protocol: http
```

#### ServiceRouter

Next we need to configure the `ServiceRouter`, the `ServiceRouter` allows you to
set configuration such as retries for a service. Retries are essential when 
running canary deployments as they protect the end user in the instance that the deployed 
canary is faulty.

```yaml
---
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceRouter
metadata:
  name: api
spec:
  routes:
  - destination:
      service: "api"
      numRetries: 3
      retryOnStatusCodes: [500, 503]
```

Lastly you need to confiugre the `ServiceResolver`, a `ServiceResolver` allows a
virtual subsets of a Consul service to be defined. These subsets are configured to 
direct traffic to the `Primary` or the currently deployed service, and the `Canary`
version of the service.  

The `TrafficSplitter` which is automatically configured Flagger uses the subsets defined in
in the `ServiceResolver` to split traffic between the two versions.   The configuration for 
this is based on Consul's filter options: https://www.consul.io/api-docs/health#filtering-2 

When Flagger takes control of your Pod it appends `primary` to the name, and since the ID  
of the service in Consul is the Pod name we can use this to create the subsets.

```yaml
---
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceResolver
metadata:
  name: api
spec:
  defaultSubset: api-primary
  subsets:
    api-primary:
      filter: "Service.ID contains \"api-primary\""
      onlyPassing: true
    api-canary:
      filter: "Service.ID not contains \"api-primary\""
      onlyPassing: true
```

#### Add the Consul config to the cluster

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>
<TabItem value="shipyard">

```shell
kubectl apply -f ./consul-config.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal:

```shell
kubectl apply -f ./consul-config.yaml
```

</TabItem>
</Tabs>


## Add the Flagger config

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>
<TabItem value="shipyard">

```shell
kubectl apply -f ./consul-config.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal:

```shell
kubectl apply -f ./consul-config.yaml
```

</TabItem>
</Tabs>
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