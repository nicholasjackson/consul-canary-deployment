# Installation Instructions

## Helm Charts

### Consul

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul -f ./helm/consul-values.yaml
```

### Cert Mananager

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-mananger jetstack/cert-manager -f ./helm/cert-manager-values.yaml
```

### Prometheus

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -f ./helm/prometheus-values.yaml
```

### Grafana

```
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana -f ./helm/grafana-values.yaml
```

### Loki

```
helm install promtail grafana/promtail -f ./helm/promtail-values.yaml
helm install loki grafana/loki
```

### Flagger

```
helm repo add flagger https://flagger.app
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
helm install flagger flagger/flagger -f ./helm/flagger-values.yaml
```

### Consul-SMI Controller

```
helm repo add smi-controler https://nicholasjackson.io/smi-controller-sdk/
helm install smi-controller smi-controller/smi-controller -f ./helm/consul-smi-controller.yaml
```

## Log into Grafana

Get the username and password


```
grafana_username=$(kubectl get secrets grafana -o json | jq -r '.data."admin-user"' | base64 -d)
grafana_password=$(kubectl get secrets grafana -o json | jq -r '.data."admin-password"' | base64 -d)
echo "user: $grafana_username"
echo "password: $grafana_password"
```
