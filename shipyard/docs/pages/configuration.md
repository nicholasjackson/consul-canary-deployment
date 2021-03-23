---
id: configuration
title: Consul Configuration Entries
sidebar_label: Consul Configuration
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Flagger will automatically control the creation and updatea of the TrafficSplit config, however you need to add manually configure the 
other elements. Let's walk through this process.

## ServiceDefaults

[https://www.consul.io/docs/connect/config-entries/service-defaults](https://www.consul.io/docs/connect/config-entries/service-defaults)

The first configuration element is `ServiceDefaults`, this configuration informs Consul that the services `web` and `api` are 
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

## ServiceRouter

Next we need to configure the `ServiceRouter`, the `ServiceRouter` allows you to
set configuration such as retries for a service. Retries are essential when 
running canary deployments as they protect the end user in the instance that the deployed 
canary is faulty.

```yaml title="/app/consul-config.yaml"
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

Lastly you need to configure the `ServiceResolver`, a `ServiceResolver` allows a
virtual subsets of a Consul service to be defined. These subsets are configured to 
direct traffic to the `Primary` or the currently deployed service, and the `Canary`
version of the service.  

The `TrafficSplitter` which is automatically configured Flagger uses the subsets defined in
in the `ServiceResolver` to split traffic between the two versions.   The configuration for 
this is based on Consul's filter options: [https://www.consul.io/api-docs/health#filtering-2](https://www.consul.io/api-docs/health#filtering-2)

When Flagger takes control of your Pod it appends `primary` to the name, and since the ID of the service in Consul is the Pod 
name we can use this to create the subsets.

```yaml title="/app/consul-config.yaml"
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

## Adding the Consul config to the Kubernetes cluster

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>
<TabItem value="shipyard">

If you are running the application in Docker using Shipyard, you can run the following command in the terminal below to apply the
config to Consul.

```shell
kubectl apply -f ./consul-config.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

If you prefer to use your own terminal, you can also set the required environment variables for your local terminal
with the command: `eval $(shipyard env)`

</TabItem>
<TabItem value="external">

In your terminal run the following command to add the Consul config entries to Kubernetes.

```shell
kubectl apply -f ./app/consul-config.yaml
```

<p>
<Terminal target="local" workdir="./" expanded />
</p>

</TabItem>
</Tabs>

The Kubernetes controller reads the custom resources and submits them to the Consul cluster, you can


If you are running the application in Docker using Shipyard, you can run the following command in the terminal below to apply the
config to Consul. To show the configuration entries using the Consul CLI you can use the following command.

```shell
consul config list --kind service-defaults
```

You can also view these using `kubectl`

```shell
kubectl get ServiceDefaults
```

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>

<TabItem value="shipyard">

Try running the previous commands in the terminal below:

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

Try running the previous commands in your terminal.

</TabItem>
</Tabs>

Now that the Consul configuration has been completed, let's see how to configure flagger.