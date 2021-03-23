---
id: flagger
title: Configuring Flagger
sidebar_label: Flagger Configuration
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

To allow `Flagger` to control the deployment process you need to configure it. There are two resources that
need to be created a `MetricTemplate` to define the Prometheus query to get the health of the deployment, and 
a `Canary` resource which defines the actual Flagger config.

## MetricTemplate

The `MetricTemplate` defines the query that Flagger will use to check the health of the Canary. The following
query gets the number of succesful requests, divides it by the total requests to return the sucess percentage
and then multiplies this by 100.

```yaml title="/app/flagger.yaml"
---
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: consul-requests
  namespace: default
spec:
  provider:
    type: prometheus
    address: http://prometheus-kube-prometheus-prometheus.default.svc:9090
  query: |
    sum(
      rate(
        envoy_cluster_upstream_rq{
          namespace="{{ namespace }}",
          pod=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)",
          envoy_cluster_name="local_app",
          envoy_response_code!~"5.*"
        }[{{ interval }}]
      )
    )
    /
    sum(
      rate(
        envoy_cluster_upstream_rq{
          namespace="{{ namespace }}",
          envoy_cluster_name="local_app",
          pod=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)"
        }[{{ interval }}]
      )
    )
    * 100
```

## Canary

Next you configure the `Canary`, the `Canary` resource defines the deployment that Flagger will control
and the parameters for the roll out. In the `analysis` section of the following resouce definition, you can
see these parameters. The definition tells flagger that you would like to increase the traffic sent to the canary 
by 10% when the success rate is 99% or greater.

```yaml title="/app/flagger.yaml"
---
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api
  namespace: default
spec:
  provider: linkerd
  # deployment reference
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  # the maximum time in seconds for the canary deployment
  # to make progress before it is rollback (default 600s)
  progressDeadlineSeconds: 60
  service:
    # ClusterIP port number
    port: 9090
    # container port number or name (optional)
    targetPort: 9090
  analysis:
    # schedule interval (default 60s)
    interval: 30s
    # max number of failed metric checks before rollback
    threshold: 5
    # max traffic percentage routed to canary
    # percentage (0-100)
    maxWeight: 80
    # canary increment step
    # percentage (0-100)
    stepWeight: 10
    # Linkerd Prometheus checks
    metrics:
    - name: "consul-requests"
      templateRef:
        name: consul-requests
        # namespace is optional
        # when not specified, the canary namespace will be used
        namespace: default
      # minimum req success rate (non 5xx responses)
      # percentage (0-100)
      thresholdRange:
        min: 99
      interval: 1m
```


## Adding the Flagger config

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>
<TabItem value="shipyard">

To apply the configuration to the server and to create the Canary, run the following command in the terminal below. 

```shell
kubectl apply -f ./flagger.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal run the following command:

```shell
kubectl apply -f ./app/flagger.yaml
```

</TabItem>
</Tabs>

If you check the status of the Canary resource, you will see that it is `Initializing`.

```shell
root@tools:/app# kubectl get Canary
NAME   STATUS         WEIGHT   LASTTRANSITIONTIME
api    Initializing   0        2021-03-09T16:16:49Z
```

Flagger is currently looking for a deployemnt named `api` which you have not yet created. Let's do that next.
