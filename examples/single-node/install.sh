#!/usr/bin/env bash
set -euo pipefail

# SPDX-License-Identifier: Apache-2.0
# Single-node preview installer for Kube-DC using k3d + ingress-nginx + Keycloak

ROOT_DIR="$(cd "$(dirname "$0")"/../.. && pwd)"
EX_DIR="${ROOT_DIR}/examples/single-node"
K3D_CLUSTER_NAME="kdc"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need docker
need k3d
need kubectl
need helm

mkdir -p "$HOME/.kube-dc"
# Create a minimal kube auth file expected by the manager
cat > "$HOME/.kube-dc/auth-conf.yaml" <<'EOF'
apiVersion: v1
kind: Config
clusters: []
users: []
contexts: []
current-context: ""
EOF

echo "[1/5] Creating k3d cluster..."
if k3d cluster list | grep -q "^${K3D_CLUSTER_NAME}\b"; then
  echo "k3d cluster '${K3D_CLUSTER_NAME}' already exists, skipping create."
else
  k3d cluster create --config "${EX_DIR}/k3d-cluster.yaml"
fi

kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Install ingress-nginx (lightweight default)
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "[2/5] Installing ingress-nginx..."
  kubectl create ns ingress-nginx || true
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
  helm repo update >/dev/null
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx \
    --set controller.watchIngressWithoutClass=true \
    --set controller.publishService.enabled=true \
    --wait
else
  echo "[2/5] ingress-nginx already installed, skipping."
fi

# Install Keycloak (dev values)
if ! kubectl get ns keycloak >/dev/null 2>&1; then
  echo "[3/5] Installing Keycloak..."
  kubectl create ns keycloak || true
  helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null
  helm repo update >/dev/null
  helm upgrade --install keycloak bitnami/keycloak -n keycloak \
    --set auth.adminUser=admin \
    --set auth.adminPassword=admin123 \
    --set proxy=passthrough \
    --set ingress.enabled=true \
    --set ingress.ingressClassName=nginx \
    --set ingress.hostname=keycloak.kube-dc.localtest.me \
    --set ingress.tls=false \
    --wait
else
  echo "[3/5] Keycloak already installed, skipping."
fi

# Add Kube-DC chart repo (local chart in this repo)
CHART_DIR="${ROOT_DIR}/charts/kube-dc"

# Ensure Helm chart metadata exists
if [ ! -f "${CHART_DIR}/Chart.yaml" ]; then
  echo "[4/5] Creating temporary Chart.yaml for local install..."
  cat > "${CHART_DIR}/Chart.yaml" <<'YAML'
apiVersion: v2
name: kube-dc
description: Kube-DC (developer preview)
type: application
version: 0.0.0-dev
appVersion: 0.0.0-dev
YAML
fi
if [ ! -f "${CHART_DIR}/values.yaml" ]; then
  cp "${EX_DIR}/values.dev.yaml" "${CHART_DIR}/values.yaml"
fi

# Deploy Kube-DC (dev values override)
echo "[5/5] Deploying Kube-DC chart..."
kubectl create ns kube-dc || true
helm upgrade --install kube-dc "${CHART_DIR}" -n kube-dc \
  -f "${EX_DIR}/values.dev.yaml" \
  --wait

cat <<EONOTE

Kube-DC Single-node preview is up (it may take a minute for pods to become Ready):
- Frontend:  http://frontend.kube-dc.localtest.me/
- Backend:   http://backend.kube-dc.localtest.me/
- Keycloak:  http://keycloak.kube-dc.localtest.me/

If you need to teardown:
  k3d cluster delete ${K3D_CLUSTER_NAME}

EONOTE
