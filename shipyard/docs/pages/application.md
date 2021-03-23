---
id: application
title: Deploying the example application
sidebar_label: Example Application
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Let's look at how we can now deploy a simple test application to the system.


## Web application

The `web` application is the public endpoint, it has an upstream service `api` which we are deploying our canary too.

This application is a plain Kubernetes deployment, with added annotations so that Consul will inject the required sidecars
and configure it to be part of the service mesh. Consul has a mutating web hook controller which looks for pods and deployments 
that have the annotation `"consul.hashicorp.com/connect-inject": "true"`. When it finds this annotation it automatically
adds the Envoy sidecar needed by the service mesh.

To communicate with the upstream you define the required service as an
annotation `"consul.hashicorp.com/connect-service-upstreams": "api:9091"` which makes the Consul service `api` available
at `localhost:9091`. The service mesh handles the actual routing of the traffic, including the retries and traffic splitting.

This deployment uses the tool `fake-service` to simulate a JSON API which calls the `api` upstream.

```yaml
---
# Web frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        metrics: enabled
      annotations:
        "consul.hashicorp.com/connect-inject": "true"
        "consul.hashicorp.com/service-tags": "v1"
        "consul.hashicorp.com/connect-service-upstreams": "api:9091"
    spec:
      containers:
      - name: web
        image: nicholasjackson/fake-service:v0.20.0
        ports:
        - containerPort: 9090
        env:
        - name: "LISTEN_ADDR"
          value: "0.0.0.0:9090"
        - name: "UPSTREAM_URIS"
          value: "http://localhost:9091"
        - name: "NAME"
          value: "web"
        - name: "MESSAGE"
          value: "Hello World"
        - name: "HTTP_CLIENT_KEEP_ALIVES"
          value: "false"
```

The deployment also has an accompanying service, this service is used for two purposes. The first is to allow 
traffic to the public endpoint running on port 9090. The second is for the Prometheus Operator, Prometheus has
been configured to scrape the `metrics` port of any service which has the label `app: metrics`. Consul automatically
exposes port `9102` on the sidecar proxy.

```yaml
# Service to expose web frontend
apiVersion: v1
kind: Service
metadata:
  name: web-service
  labels:
    app: metrics
spec:
  selector:
    app: web
  ports:
  - name: http
    protocol: TCP
    port: 9090
    targetPort: 9090
  - name: metrics
    protocol: TCP
    port: 9102
    targetPort: 9102
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

If you are running the application in Docker using Shipyard, you can run the following command in the terminal below to apply the
config to Consul.

```shell
kubectl apply -f ./web.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal run the following command to add the Consul config entries to Kubernetes.

```shell
kubectl apply -f ./app/web.yaml
```

</TabItem>
</Tabs>

## API application

The `api` is the applicaction which you are using for the canary again is a standard deployment.
This deployment like the `web` deployment also has the annotations which allow consul to add it as part of
the service mesh. It also has an additional annotation `"consul.hashicorp.com/service-tags": "v1"`, this 
annotation performs no function other than adding a tag to Consuls service catalog so that you can
easily determine the version of the application.

```yaml
---
# API service version 1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        group: api
      annotations:
        "consul.hashicorp.com/connect-inject": "true"
        "consul.hashicorp.com/service-tags": "v1"
    spec:
      containers:
      - name: api
        image: nicholasjackson/fake-service:v0.20.0
        ports:
        - containerPort: 9090
        env:
        - name: "LISTEN_ADDR"
          value: "127.0.0.1:9090"
        - name: "NAME"
          value: "api"
        - name: "MESSAGE"
          value: "Response from API"
          #  - name: "ERROR_RATE"
          #    value: "0.2"
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

If you are running the application in Docker using Shipyard, you can run the following command in the terminal below to apply the
config to Consul.

```shell
kubectl apply -f ./api.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal run the following command to add the Consul config entries to Kubernetes.

```shell
kubectl apply -f ./app/api.yaml
```

</TabItem>
</Tabs>

Flagger will detect that the API has been deployed and will copy the deployment renaming it api-primary, if you 
look at the pods running in the cluster you will see Flagger creating this new deployment.

```shell
root@tools:/app# kubectl get pod -l 'app in (api-primary,api)'
NAME                                                          READY   STATUS     RESTARTS   AGE
api-58d94dbdd7-jt5xf                                          3/3     Running    0          13s
api-58d94dbdd7-k4xrl                                          3/3     Running    0          13s
api-58d94dbdd7-s7mxr                                          3/3     Running    0          13s
api-primary-6b4f9d97d7-cmb57                                  0/3     Init:0/1   0          0s
api-primary-6b4f9d97d7-j2k8p                                  0/3     Init:0/1   0          0s
api-primary-6b4f9d97d7-vbgqd                                  0/3     Init:0/1   0          0s
```

If you look at the deployments you will see that there are now two for the API.

```shell
root@tools:/app# kubectl get deployment -l 'app in (api-primary,api)'
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
api-primary   3/3     3            3           12m
api           0/0     0            0           12m
```

Flagger duplicates the original deployment renaming it with a prefix `-primary`, it then scales the original deployment to 0.
The `api-primary` deployment exists as long as you have the Flagger Canary configured, it is the current good version deployed.
When you deploy a new version of your application, this will use the original `api`, flagger detects this new version
and will start to send traffic to it.

You will see how this all works in a bit, first let's create some fake load for the application.