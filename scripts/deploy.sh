#!/usr/bin/env bash
# usage: deploy.sh <rolling|blue-green|canary|shadow|ab-testing> <image:tag>
set -euo pipefail
S=$1; IMG=$2; D="$(dirname "$0")/../k8s"
case $S in
  rolling)
    kubectl apply -f $D/rolling/rolling.yaml
    kubectl set image deployment/aceest-rolling aceest=$IMG
    kubectl rollout status deployment/aceest-rolling --timeout=120s ;;
  blue-green)
    kubectl apply -f $D/blue-green/
    LIVE=$(kubectl get svc aceest-bluegreen -o jsonpath='{.spec.selector.slot}')
    NEW=$([ "$LIVE" = blue ] && echo green || echo blue)
    kubectl set image deployment/aceest-$NEW aceest=$IMG
    kubectl rollout status deployment/aceest-$NEW --timeout=120s
    kubectl patch svc aceest-bluegreen -p "{\"spec\":{\"selector\":{\"app\":\"aceest\",\"slot\":\"$NEW\"}}}"
    echo "Traffic switched $LIVE -> $NEW" ;;
  canary)
    kubectl apply -f $D/canary/canary.yaml
    kubectl set image deployment/aceest-canary aceest=$IMG
    kubectl rollout status deployment/aceest-canary --timeout=120s
    echo "Canary live at ~25%. Promote: kubectl set image deployment/aceest-stable aceest=$IMG" ;;
  shadow)
    kubectl apply -f $D/shadow/shadow.yaml
    kubectl set image deployment/aceest-shadow aceest=$IMG
    kubectl rollout status deployment/aceest-shadow --timeout=120s ;;
  ab-testing)
    kubectl apply -f $D/ab-testing/ab.yaml
    kubectl set image deployment/aceest-b aceest=$IMG
    kubectl rollout status deployment/aceest-b --timeout=120s ;;
esac
