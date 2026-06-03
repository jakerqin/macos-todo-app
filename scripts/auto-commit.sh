#!/bin/bash

# Auto-commit script for development workflow
# Usage: ./scripts/auto-commit.sh "commit message"

set -e

# Get commit message from argument or prompt
if [ -z "$1" ]; then
    echo "Please provide a commit message:"
    read -r COMMIT_MSG
else
    COMMIT_MSG="$1"
fi

# Check if there are changes
if git diff --quiet && git diff --staged --quiet; then
    echo "No changes to commit."
    exit 0
fi

# Show what will be committed
echo "Changes to be committed:"
git status --porcelain

# Add all changes
git add .

# Commit with message
git commit -m "$COMMIT_MSG"

# Push to origin
git push origin main

echo "✅ Changes committed and pushed to GitHub!"
echo "🔗 View at: https://github.com/jakerqin/macos-todo-app"