#!/usr/bin/env bash
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8081:443 &
kubectl port-forward svc/grafana -n monitoring 8082:80 &
