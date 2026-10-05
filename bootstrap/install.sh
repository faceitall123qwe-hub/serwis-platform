#!/usr/bin/env bash
# Installs Argo CD into the current cluster and hands everything else over to it.
# REVISION selects the git revision Argo CD deploys (defaults to main).
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/faceitall123qwe-hub/repair-shop-k8s-platform.git}"
REVISION="${REVISION:-main}"
cd "$(dirname "$0")/.."

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd --version 10.9.6 \
  --namespace argocd --create-namespace \
  --values bootstrap/argocd-values.yaml --wait

# App secrets are generated here and never committed. In a real environment
# they would come from External Secrets / Sealed Secrets.
kubectl create namespace serwis --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl -n serwis get secret serwis-app >/dev/null 2>&1; then
  kubectl -n serwis create secret generic serwis-app \
    --from-literal=SESSION_SECRET="$(openssl rand -base64 32)" \
    --from-literal=IP_HASH_SALT="$(openssl rand -base64 32)" \
    --from-literal=ADMIN_EMAIL="admin@serwis.local" \
    --from-literal=ADMIN_PASSWORD="$(openssl rand -base64 18)"
fi

# Grafana's chart would otherwise generate a new random password on every Argo CD render.
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl -n monitoring get secret grafana-admin >/dev/null 2>&1; then
  kubectl -n monitoring create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$(openssl rand -base64 18)"
fi

helm template root apps --set repoURL="$REPO_URL" --set revision="$REVISION" \
  --show-only templates/root.yaml | kubectl apply -f -

echo "Argo CD is syncing revision $REVISION."
echo "Argo CD  admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "Grafana  admin / $(kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d)"
