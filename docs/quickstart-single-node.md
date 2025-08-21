# Single-node Developer Preview (lowest requirements)

This guide sets up a lightweight, single-node environment to preview Kube-DC UI and basic APIs on your laptop or a small VM. It’s for exploration only (no production networking/VMs/HA).

What you’ll get:
- A local Kubernetes (k3d) cluster
- Keycloak for authentication
- Kube-DC Manager, Backend, and Frontend
- Ingress via ingress-nginx

Out of scope in this preview:
- Kube-OVN/Multus advanced networking
- KubeVirt (VMs)
- Production-grade hardening

## Requirements
- macOS/Linux with Docker
- k3d, kubectl, helm installed
- Recommended: 4 CPU, 8 GB RAM

## Quick start

1) Run the helper installer

The repo includes a helper script that creates a k3d cluster, installs ingress-nginx and Keycloak, and deploys Kube-DC:

- `examples/single-node/install.sh`

2) Access

- Frontend: http://frontend.kube-dc.localtest.me/
- Backend (health): http://backend.kube-dc.localtest.me/
- Keycloak: http://keycloak.kube-dc.localtest.me/

Default Keycloak admin: `admin / admin123`

Note: Frontend login redirects to Keycloak. Many features are limited in this preview.

## Files in this example
- `examples/single-node/k3d-cluster.yaml` – cluster config with host port mappings and a bind-mount for the auth file
- `examples/single-node/values.dev.yaml` – minimal overrides for the Helm chart
- `examples/single-node/install.sh` – provisioning script (idempotent)

## Troubleshooting
- If ingresses don’t resolve, ensure `*.localtest.me` resolves to 127.0.0.1 and ports 80/443 are free.
- If the Manager pod can’t read the auth file, confirm the k3d server node has the bind-mounted directory and the file exists: `/etc/rancher/auth-conf.yaml`.
- For a more complete setup (networking, VMs, monitoring), see `installer/kube-dc/`.
