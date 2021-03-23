---
id: load_generation
title: Generating load with K3s
sidebar_label: Generating Load
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

In order to determine that the new service is running correctly Flagger looks at he metrics emitted from the Service Mesh that are
created as traffic flows through the system. In production your customers are hopefully going to generate this traffic for you, however 
in your development environment you can simulate the load using a tool like [https://k6.io/](https://k6.io/).

The following extract shows a simple load generation using K6, it creates `10` virtual users and calls the endpoint 
`http://web-service.default.svc:9090` every second.

```javascript title="/app/load-generator.yaml"
import http from 'k6/http';
import { sleep, check } from 'k6';
import { Counter } from 'k6/metrics';

// A simple counter for http requests

export const requests = new Counter('http_reqs');

// you can specify stages of your test (ramp up/down patterns) through the options object
// target is the number of VUs you are aiming for

export const options = {
  vus: 10,
  duration: '30m',
};

export default function () {
  // our HTTP request, note that we are saving the response to res, which can be accessed later

  const res = http.get('http://web-service.default.svc:9090');

  sleep(1);

  const checkRes = check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
```

You can run the load test as a deployment in Kubernetes, the previous load generation script can be provided to the `k6` application
using a `ConfigMap`.

```yaml title="/app/load-generator.yaml"
---
# Load test
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator-deployment
  labels:
    app: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-generator
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: load-generator
        image: loadimpact/k6
        command: ["k6", "run", "/etc/config/load_test.js"]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
        - name: config-volume
          configMap:
            name: load-generator
```

Let's deploy this to the cluster and start generating some load

<Tabs
  className="unique-tabs"
  groupId="environment"
  defaultValue="shipyard"
  values={[
    {label: 'Shipyard', value: 'shipyard'},
    {label: 'External Cluster', value: 'external'},
  ]}>
<TabItem value="shipyard">

To apply the configuration to the server and to start generating load, run the following command in the terminal below. 

```shell
kubectl apply -f ./load-generator.yaml
```

<p>
<Terminal target="tools.container.shipyard.run" shell="/bin/bash" workdir="/app" user="root" expanded />
</p>

</TabItem>
<TabItem value="external">

In your terminal run the following command:

```shell
kubectl apply -f ./app/load-generator.yaml
```

</TabItem>
</Tabs>

Now there is some traffic flowing through the system let's deploy a simple dashboard so we can see what is going on.