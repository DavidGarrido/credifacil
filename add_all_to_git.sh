#!/bin/bash

set -e

PROJECTS=("frontend" "landlord-creditapi" "tenant-api")

echo "Starting 'git add .' operation across projects..."

for PROJECT in "${PROJECTS[@]}"; do
    echo "--- Processing project: $PROJECT ---"
    if [ -d "$PROJECT" ]; then
        cd "$PROJECT"
        echo "Running 'git add .' in $PROJECT..."
        git add .
        echo "'git add .' completed for $PROJECT."
        cd ..
    else
        echo "Error: Project directory '$PROJECT' not found. Skipping."
    fi
done

echo "All projects processed."