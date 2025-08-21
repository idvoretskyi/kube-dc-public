# Kube-DC Single-node Example

This directory contains a minimal single-node developer preview setup using k3d.

Quick start:
- Run `./install.sh`
- Open:
  - Frontend: http://frontend.kube-dc.localtest.me/
  - Backend:  http://backend.kube-dc.localtest.me/
  - Keycloak: http://keycloak.kube-dc.localtest.me/

Teardown:
- `k3d cluster delete kdc`
