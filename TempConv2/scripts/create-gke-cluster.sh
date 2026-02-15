#!/bin/bash
# Create a GKE cluster for TempConv2 (amd64 nodes).
# Usage: ./create-gke-cluster.sh PROJECT_ID [CLUSTER_NAME] [ZONE]

set -e

PROJECT_ID="${1:?Provide PROJECT_ID}"
CLUSTER_NAME="${2:-tempconv2-cluster}"
ZONE="${3:-europe-west1-b}"

echo "=== Creating GKE cluster ==="
echo "Project: $PROJECT_ID  Cluster: $CLUSTER_NAME  Zone: $ZONE"
echo ""

gcloud config set project $PROJECT_ID
gcloud services enable container.googleapis.com containerregistry.googleapis.com

echo "Creating cluster (this may take a few minutes)..."
gcloud container clusters create $CLUSTER_NAME \
  --zone $ZONE \
  --machine-type e2-small \
  --num-nodes 3 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 5 \
  --disk-size 20 \
  --enable-autorepair \
  --enable-autoupgrade

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

echo "=== Cluster ready ==="
kubectl cluster-info
kubectl get nodes
