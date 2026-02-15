#!/bin/bash
# Build and push TempConv2 Docker images to GCR (linux/amd64 for GKE).
# Usage: ./build-and-push.sh PROJECT_ID [TAG]

set -e

PROJECT_ID="${1:?Please provide PROJECT_ID}"
TAG="${2:-latest}"

echo "=== Building TempConv2 for GKE (amd64) ==="
echo "Project: $PROJECT_ID"
echo "Tag: $TAG"
echo ""

gcloud auth configure-docker gcr.io --quiet

echo "=== Building Backend ==="
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/tempconv2-backend:$TAG ./backend
docker push gcr.io/$PROJECT_ID/tempconv2-backend:$TAG

echo "=== Building Frontend (nginx.conf for K8s: proxy /tempconv... to backend:8080) ==="
docker build --platform linux/amd64 \
  --build-arg NGINX_CONF=nginx.conf \
  -t gcr.io/$PROJECT_ID/tempconv2-frontend:$TAG ./frontend
docker push gcr.io/$PROJECT_ID/tempconv2-frontend:$TAG

echo "=== Done ==="
echo "  gcr.io/$PROJECT_ID/tempconv2-backend:$TAG"
echo "  gcr.io/$PROJECT_ID/tempconv2-frontend:$TAG"
