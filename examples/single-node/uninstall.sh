#!/usr/bin/env bash
set -euo pipefail

# SPDX-License-Identifier: Apache-2.0
# Uninstall the single-node Kube-DC developer preview
# Usage:
#   ./uninstall.sh [--purge]
#
# --purge  Also remove local state at $HOME/.kube-dc

K3D_CLUSTER_NAME=${K3D_CLUSTER_NAME:-kdc}
PURGE=0
if [[ ${1:-} == "--purge" ]]; then
  PURGE=1
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need k3d
need kubectl
need helm

cluster_exists() {
  k3d cluster list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$K3D_CLUSTER_NAME"
}

ns_exists() {
  kubectl get ns "$1" >/dev/null 2>&1
}

hr_exists() {
  # helm release exists in namespace
  local ns="$1"; local rel="$2"
  helm status "$rel" -n "$ns" >/dev/null 2>&1
}

echo "[1/3] Cleaning in-cluster resources (if cluster exists)..."
if cluster_exists; then
  # Attempt to uninstall releases if present
  if ns_exists kube-dc && hr_exists kube-dc kube-dc; then
    echo "- Uninstalling helm release kube-dc (ns kube-dc)"
    helm uninstall kube-dc -n kube-dc || true
  fi
  if ns_exists keycloak && hr_exists keycloak keycloak; then
    echo "- Uninstalling helm release keycloak (ns keycloak)"
    helm uninstall keycloak -n keycloak || true
  fi
  if ns_exists ingress-nginx && hr_exists ingress-nginx ingress-nginx; then
    echo "- Uninstalling helm release ingress-nginx (ns ingress-nginx)"
    helm uninstall ingress-nginx -n ingress-nginx || true
  fi

  # Delete namespaces if they remain
  for ns in kube-dc keycloak ingress-nginx; do
    if ns_exists "$ns"; then
      echo "- Deleting namespace $ns"
      kubectl delete ns "$ns" --wait=false || true
    fi
  done
else
  echo "- Cluster '$K3D_CLUSTER_NAME' not found; skipping in-cluster cleanup."
fi

# Small grace period for background deletions
sleep 2 || true

echo "[2/3] Deleting k3d cluster (if exists)..."
if cluster_exists; then
  k3d cluster delete "$K3D_CLUSTER_NAME" || true
else
  echo "- Cluster '$K3D_CLUSTER_NAME' already absent."
fi

if [[ "$PURGE" == "1" ]]; then
  echo "[3/3] Purging local state at $HOME/.kube-dc"
  rm -rf "$HOME/.kube-dc" || true
else
  echo "[3/3] Skipping purge (pass --purge to remove $HOME/.kube-dc)"
fi

echo "Done."
