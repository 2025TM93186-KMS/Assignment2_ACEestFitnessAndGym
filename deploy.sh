#!/usr/bin/env bash
# Usage: ./deploy.sh <rolling|bluegreen|bluegreen-switch|bluegreen-rollback|canary|canary-promote|canary-rollback|abshadow|rollback>
set -euo pipefail
NS=aceest
case "$1" in
  rolling)             kubectl apply -f k8s/namespace.yaml -f k8s/rolling.yaml ;;
  bluegreen)           kubectl apply -f k8s/namespace.yaml -f k8s/blue-green.yaml ;;
  bluegreen-switch)    kubectl -n $NS patch svc aceest-bg -p '{"spec":{"selector":{"app":"aceest-bg","slot":"green"}}}' ;;
  bluegreen-rollback)  kubectl -n $NS patch svc aceest-bg -p '{"spec":{"selector":{"app":"aceest-bg","slot":"blue"}}}' ;;
  canary)              kubectl apply -f k8s/namespace.yaml -f k8s/canary.yaml ;;
  canary-promote)      kubectl -n $NS scale deploy/aceest-canary --replicas=10; kubectl -n $NS scale deploy/aceest-stable --replicas=0 ;;
  canary-rollback)     kubectl -n $NS scale deploy/aceest-canary --replicas=0;  kubectl -n $NS scale deploy/aceest-stable --replicas=9 ;;
  abshadow)            kubectl apply -f k8s/namespace.yaml -f k8s/ab-testing-shadow.yaml ;;
  rollback)            kubectl -n $NS rollout undo deployment/aceest-rolling; kubectl -n $NS rollout status deployment/aceest-rolling ;;
esac
