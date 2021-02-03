#!/bin/bash

function expose() {
  kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 & 
  kubectl port-forward svc/web-service 9091:9090 & 
  kubectl port-forward svc/grafana 8080:80 & 
  kubectl port-forward svc/consul-server 8500:8500 & 
}

function stop_expose() {
  pkill kubectl
}

function grafana_pass() {
  grafana_username=$(kubectl get secrets grafana -o json | jq -r '.data."admin-user"' | base64 -d)
  grafana_password=$(kubectl get secrets grafana -o json | jq -r '.data."admin-password"' | base64 -d)
  echo "user: $grafana_username"
  echo "password: $grafana_password"
}

function fetch_config() {
  gcloud container clusters get-credentials $(terraform output name) --zone $(terraform output location) --project $(terraform output project)
}

case "$1" in
  expose)
    expose
    ;;
  stop)
    stop_expose
    ;;
  grafana_pass)
    grafana_pass
    ;;
  fetch_config)
    fetch_config
    ;;
  *)
    echo "Usage:"
    echo "       expose         - expose Kubernetes services to localhost"
    echo "       stop           - stop exposing Kubernetes services to localhost"
    echo "       grafana_pass   - Show the Grafana username and password"
    echo "       fetch_config   - Fetch the Kubernetes config file and configure kubectl" 
    exit 1
  esac

