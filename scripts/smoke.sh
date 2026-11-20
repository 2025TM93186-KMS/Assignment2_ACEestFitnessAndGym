#!/usr/bin/env bash
set -euo pipefail
URL="http://$(minikube ip):30080"
for i in 1 2 3 4 5; do
  curl -fsS "$URL/api/health" && exit 0 || sleep 3
done
echo "Smoke test failed"; exit 1
