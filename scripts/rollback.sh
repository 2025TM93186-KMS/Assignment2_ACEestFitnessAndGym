#!/usr/bin/env bash
# usage: rollback.sh <strategy>
set -uo pipefail
case $1 in
  rolling)    kubectl rollout undo deployment/aceest-rolling ;;
  blue-green) CUR=$(kubectl get svc aceest-bluegreen -o jsonpath='{.spec.selector.slot}')
              PREV=$([ "$CUR" = blue ] && echo green || echo blue)
              kubectl patch svc aceest-bluegreen -p "{\"spec\":{\"selector\":{\"app\":\"aceest\",\"slot\":\"$PREV\"}}}" ;;
  canary)     kubectl scale deployment/aceest-canary --replicas=0 ;;
  shadow)     kubectl rollout undo deployment/aceest-shadow ;;
  ab-testing) kubectl rollout undo deployment/aceest-b ;;
esac
