#!/usr/bin/env bash
set -e

# Navigate to the dotfiles repo root
cd "$(dirname "$0")/.."

# Local branch to rebase
BRANCH="main"

# Subtree directory
SUBTREE_DIR="nvim"

# Upstream remote info
REMOTE_NAME="kickstart"
REMOTE_URL="https://github.com/nvim-lua/kickstart.nvim.git"
REMOTE_BRANCH="master"

# Ensure we are on the local branch
git checkout "$BRANCH"

# Check if remote exists
if git remote get-url "$REMOTE_NAME" &>/dev/null; then
    # Verify remote URL
    CURRENT_URL=$(git remote get-url "$REMOTE_NAME")
    if [ "$CURRENT_URL" != "$REMOTE_URL" ]; then
        echo "Error: Remote '$REMOTE_NAME' exists but points to '$CURRENT_URL', expected '$REMOTE_URL'."
        echo "Please fix the remote URL before running this script."
        exit 1
    fi
else
    # Remote does not exist; add it
    echo "Adding remote '$REMOTE_NAME' -> $REMOTE_URL"
    git remote add "$REMOTE_NAME" "$REMOTE_URL"
fi

# Fetch upstream branch
git fetch "$REMOTE_NAME" "$REMOTE_BRANCH"

# Pull updates into the subtree directory only
echo "Updating subtree '$SUBTREE_DIR' from '$REMOTE_NAME/$REMOTE_BRANCH'..."
git subtree pull --prefix="$SUBTREE_DIR" "$REMOTE_NAME" "$REMOTE_BRANCH" --squash

echo "✅ Subtree '$SUBTREE_DIR' updated successfully!"
