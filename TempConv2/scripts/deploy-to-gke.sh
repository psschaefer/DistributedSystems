#!/bin/bash
# Deploy TempConv2 to GKE.
# Usage: ./deploy-to-gke.sh PROJECT_ID CLUSTER_NAME [ZONE]

set -e

PROJECT_ID="${1:?Provide PROJECT_ID}"
CLUSTER_NAME="${2:?Provide CLUSTER_NAME}"
ZONE="${3:-europe-west1-b}"

echo "=== Deploying TempConv2 to GKE ==="
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
kubectl apply -f k8s/hpa.yaml

echo "=== Deployment complete ==="
echo "Waiting for frontend external IP..."
kubectl get service frontend -n tempconv2 --watch
