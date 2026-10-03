#!/usr/bin/env bash
# Waits until every Argo CD application is Synced and Healthy.
set -euo pipefail
timeout="${1:-900}"
deadline=$(( $(date +%s) + timeout ))

while true; do
  status=$(kubectl -n argocd get applications.argoproj.io \
    -o jsonpath='{range .items[*]}{.metadata.name}={.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null || true)
  pending=$(echo "$status" | grep -v '=Synced/Healthy$' || true)
  if [[ -n "$status" && -z "$pending" && $(echo "$status" | wc -l) -ge 9 ]]; then
    echo "$status"
    echo "all applications synced and healthy"
    exit 0
  fi
  if (( $(date +%s) > deadline )); then
    echo "timed out; current state:"
    echo "$status"
    exit 1
  fi
  echo "waiting: $(echo "$pending" | tr '\n' ' ')"
  sleep 15
done
