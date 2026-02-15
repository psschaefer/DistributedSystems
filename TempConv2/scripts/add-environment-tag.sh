#!/bin/bash
# Add the recommended 'environment' tag to a GCP project (e.g. Development, Production).
# Usage: ./add-environment-tag.sh PROJECT_ID [ENVIRONMENT]
# Example: ./add-environment-tag.sh tempconv2-487514 Development

set -e

PROJECT_ID="${1:?Provide PROJECT_ID}"
ENV="${2:-Development}"

echo "Adding environment tag to project $PROJECT_ID (value: $ENV)"
echo ""

# 1. Create tag key "environment" under the project (if it doesn't exist)
KEY_ID=$(gcloud resource-manager tags keys list --parent=projects/$PROJECT_ID --format='value(name)' --filter='shortName:environment' 2>/dev/null | head -1)
if [ -z "$KEY_ID" ]; then
  echo "Creating tag key 'environment'..."
  KEY_ID=$(gcloud resource-manager tags keys create environment \
    --parent=projects/$PROJECT_ID \
    --format='value(name)')
  echo "Created $KEY_ID"
else
  echo "Tag key 'environment' already exists: $KEY_ID"
fi

# 2. Create tag value (e.g. Development) under the key (if it doesn't exist)
VALUE_ID=$(gcloud resource-manager tags values list --parent=$KEY_ID --format='value(name)' --filter="shortName:$ENV" 2>/dev/null | head -1)
if [ -z "$VALUE_ID" ]; then
  echo "Creating tag value '$ENV'..."
  VALUE_ID=$(gcloud resource-manager tags values create "$ENV" \
    --parent=$KEY_ID \
    --format='value(name)')
  echo "Created $VALUE_ID"
else
  echo "Tag value '$ENV' already exists: $VALUE_ID"
fi

# 3. Bind the tag value to the project
PARENT="//cloudresourcemanager.googleapis.com/projects/$PROJECT_ID"
if gcloud resource-manager tags bindings list --parent=$PARENT --format='value(tagValue)' 2>/dev/null | grep -q "$VALUE_ID"; then
  echo "Tag already bound to project."
else
  echo "Binding tag to project..."
  gcloud resource-manager tags bindings create \
    --parent=$PARENT \
    --tag-value=$VALUE_ID
  echo "Done."
fi

echo ""
echo "Project $PROJECT_ID now has tag: environment = $ENV"
