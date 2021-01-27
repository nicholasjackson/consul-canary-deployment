#!/bin/bash

kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 & 
kubectl port-forward svc/web-service 9091:9090 & 
kubectl port-forward svc/grafana 8080:80 & 
kubectl port-forward svc/consul-server 8500:8500 & 
