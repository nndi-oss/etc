#!/bin/bash
# NOTE: you have to customize your worktree directory
WORKTREE_BASE_DIR="/home/<yourusername>/Projects/worktrees"

check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "❌ Error: This script must be run inside a Git repository."
        exit 1
    fi
}

prompt_for_branch() {
    read -r -p "Enter the branch name (e.g., feature/new-thing, bugfix/123): " WORKTREE_BRANCH_NAME
    if [ -z "$WORKTREE_BRANCH_NAME" ]; then
        echo "❌ Branch name cannot be empty."
        exit 1
    fi
}

check_git_repo

if [ ! -d "$WORKTREE_BASE_DIR" ]; then
    echo "ℹ️ Base worktree directory '$WORKTREE_BASE_DIR' does not exist."
    mkdir -p "$WORKTREE_BASE_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Error: Could not create base worktree directory '$WORKTREE_BASE_DIR'."
        exit 1
    fi
    echo "✅ Created base worktree directory."
fi

# 1. Get the current repository's base directory name
# 'git rev-parse --show-toplevel' gets the absolute path to the repo root.
REPO_BASENAME=$(basename "$(git rev-parse --show-toplevel)")

prompt_for_branch

# 2. Sanitize the branch name for use in the directory path
# Replace all forward slashes '/' with hyphens '-' for a valid directory name
WORKTREE_DIR_SUFFIX=$(echo "$WORKTREE_BRANCH_NAME" | tr '/' '-')

# 3. Construct the full worktree directory path (FIX APPLIED HERE)
WORKTREE_PATH="${WORKTREE_BASE_DIR}/${REPO_BASENAME}-${WORKTREE_DIR_SUFFIX}"

# 4. Check if the worktree directory already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo "⚠️ Warning: Worktree directory '$WORKTREE_PATH' already exists."
    read -r -p "Do you want to continue and attempt to create/link the worktree anyway? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

echo "---"
echo "Repository Base: $REPO_BASENAME"
echo "Worktree Directory: $WORKTREE_PATH"
echo "Target Branch: $WORKTREE_BRANCH_NAME"
echo "---"

# 5. Create the Git worktree
echo "🚀 Creating git worktree..."
if git worktree add --track -b "$WORKTREE_BRANCH_NAME" "$WORKTREE_PATH"; then
    echo "✅ Successfully created worktree at: $WORKTREE_PATH"
    echo "   Checked out branch: $WORKTREE_BRANCH_NAME"
    echo "   To switch to it, run: cd $WORKTREE_PATH"
elif git worktree add "$WORKTREE_PATH" "$WORKTREE_BRANCH_NAME"; then
    echo "✅ Worktree successfully created at: $WORKTREE_PATH"
    echo "   It seems branch '$WORKTREE_BRANCH_NAME' already existed and was checked out."
    echo "   To switch to it, run: cd $WORKTREE_PATH"
else
    echo "❌ Error creating worktree. Check the output above for details."
    exit 1
fi
