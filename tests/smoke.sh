#!/usr/bin/env bash
# End-to-end checks against a running cluster: the app answers through the ingress,
# talks to its database, and the platform rejects workloads that break policy.
set -euo pipefail
HOST="${HOST:-serwis.127.0.0.1.nip.io}"
fail=0

check() {
  local name="$1" expected="$2" got="$3"
  if [[ "$got" == "$expected" ]]; then echo "ok   $name"; else echo "FAIL $name (expected $expected, got $got)"; fail=1; fi
}

code() { curl -s -o /dev/null -w '%{http_code}' -H "Host: $HOST" "http://127.0.0.1$1"; }

check "home page"                200 "$(code /)"
check "services page"            200 "$(code /uslugi)"
check "admin login page"         200 "$(code /panel/login)"
check "readiness incl. database" 200 "$(code '/api/health?ready=1')"
check "seeded services listed"   yes "$(curl -s -H "Host: $HOST" http://127.0.0.1/uslugi | grep -q 'Wymiana matrycy' && echo yes || echo no)"

denied() {
  if kubectl -n serwis run "$1" --restart=Never "${@:2}" >/dev/null 2>&1; then
    kubectl -n serwis delete pod "$1" --ignore-not-found >/dev/null; echo no
  else echo yes; fi
}

check "policy: :latest tag rejected"         yes "$(denied p-latest --image=nginx:latest)"
check "policy: missing limits rejected"      yes "$(denied p-limits --image=nginx:1.27)"
check "policy: unsigned own image rejected"  yes "$(denied p-unsigned --image=ghcr.io/faceitall123qwe-hub/serwis:unsigned)"

check "database: 2 instances ready" 2 "$(kubectl -n serwis get cluster serwis-db -o jsonpath='{.status.readyInstances}')"
avail=$(kubectl -n serwis get deploy serwis -o jsonpath='{.status.availableReplicas}')
check "app: 2+ replicas available"  yes "$([[ ${avail:-0} -ge 2 ]] && echo yes || echo no)"

exit $fail
