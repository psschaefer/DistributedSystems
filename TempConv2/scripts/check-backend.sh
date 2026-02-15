#!/bin/bash
# Quick backend/frontend health check for TempConv2 in GKE.
set -e
NS="${1:-tempconv2}"
echo "=== Pods (namespace: $NS) ==="
kubectl get pods -n "$NS" -o wide
echo ""
echo "=== Backend pod status (first pod) ==="
BACKEND_POD=$(kubectl get pods -n "$NS" -l app=tempconv2,component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$BACKEND_POD" ]; then
  kubectl get pod "$BACKEND_POD" -n "$NS" -o wide
  echo ""
  echo "=== Backend container (Go) logs ==="
  kubectl logs -n "$NS" "$BACKEND_POD" -c backend --tail=30
  echo ""
  echo "=== Envoy container logs ==="
  kubectl logs -n "$NS" "$BACKEND_POD" -c envoy --tail=30
else
  echo "No backend pod found."
fi
echo ""
echo "=== Frontend pod logs (nginx) ==="
FRONTEND_POD=$(kubectl get pods -n "$NS" -l app=tempconv2,component=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$FRONTEND_POD" ]; then
  kubectl logs -n "$NS" "$FRONTEND_POD" -c frontend --tail=20
fi
echo ""
echo "=== Test from frontend to backend (if pods exist) ==="
if [ -n "$FRONTEND_POD" ]; then
  kubectl exec -n "$NS" "$FRONTEND_POD" -c frontend -- wget -q -O- --timeout=2 http://backend:9091/health 2>/dev/null || echo "Health check failed."
  kubectl exec -n "$NS" "$FRONTEND_POD" -c frontend -- wget -q -O- --timeout=2 http://backend:8080/ 2>/dev/null || echo "Backend:8080 check failed (may be normal for GET /)."
fi
