#!/bin/bash
# Deploy Texas Hold'em to GKE (same cluster as TempConv2, different namespace = own external IP).
# Usage: from repo root or texasHold: ./texasHold/scripts/deploy-to-gke.sh PROJECT_ID CLUSTER_NAME [ZONE]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEXASHOLD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$TEXASHOLD_ROOT"

PROJECT_ID="${1:?Provide PROJECT_ID}"
CLUSTER_NAME="${2:?Provide CLUSTER_NAME}"
ZONE="${3:-europe-west1-b}"

echo "=== Deploying Texas Hold'em to GKE ==="
echo "Project: $PROJECT_ID  Cluster: $CLUSTER_NAME  Zone: $ZONE"
echo ""

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

echo "Updating image names with project ID..."
sed -i "s/PROJECT_ID/$PROJECT_ID/g" k8s/backend-deployment.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" k8s/frontend-deployment.yaml

echo "Applying manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

echo "=== Deployment complete ==="
echo "Get frontend external IP: kubectl get svc frontend -n texashold"
kubectl get svc frontend -n texashold
