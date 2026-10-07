#!/usr/bin/env bash
set -e

BUCKET_NAME="YOUR_S3_FRONTEND_BUCKET_NAME"

echo "Syncing frontend assets to s3://${BUCKET_NAME}..."
aws s3 sync frontend/ s3://${BUCKET_NAME}/ --delete
echo "Frontend deployment complete."