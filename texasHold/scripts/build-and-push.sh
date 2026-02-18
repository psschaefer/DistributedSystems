#!/bin/bash
# Build and push Texas Hold'em images to GCR (linux/amd64 for GKE).
# Usage: from repo root or texasHold: ./texasHold/scripts/build-and-push.sh PROJECT_ID [TAG]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEXASHOLD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$TEXASHOLD_ROOT"

PROJECT_ID="${1:?Please provide PROJECT_ID}"
TAG="${2:-latest}"

echo "=== Building Texas Hold'em for GKE (amd64) ==="
echo "Project: $PROJECT_ID  Tag: $TAG"
echo ""

gcloud auth configure-docker gcr.io --quiet

echo "=== Building Backend ==="
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/texashold-backend:$TAG ./backend
docker push gcr.io/$PROJECT_ID/texashold-backend:$TAG

echo "=== Building Frontend ==="
docker build --platform linux/amd64 --build-arg NGINX_CONF=nginx.conf -t gcr.io/$PROJECT_ID/texashold-frontend:$TAG ./frontend
docker push gcr.io/$PROJECT_ID/texashold-frontend:$TAG

echo "=== Done ==="
echo "  gcr.io/$PROJECT_ID/texashold-backend:$TAG"
echo "  gcr.io/$PROJECT_ID/texashold-frontend:$TAG"
