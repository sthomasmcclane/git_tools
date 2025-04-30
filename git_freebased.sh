#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Determine the main branch name (master or main)
MAIN_BRANCH=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

# Check if MAIN_BRANCH is empty and exit if it is
if [[ -z "$MAIN_BRANCH" ]]; then
  echo "Error: Could not determine the main branch (master or main) from the remote repository."
  echo "Please ensure that the remote repository is properly configured."
  exit 1
fi

# Display usage if -h or --help is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0"
  echo "  This script rebases the current branch onto the main branch (master or main)."
  echo "  It then prompts for confirmation before force pushing the rebased branch."
  exit 0
fi

git checkout "$MAIN_BRANCH"

git pull origin "$MAIN_BRANCH"

git checkout "$BRANCH"

# Attempt to rebase
git rebase "$MAIN_BRANCH"

# Check if the rebase was successful
if [[ $? -ne 0 ]]; then
  echo ""
  echo "Rebase encountered conflicts!"
  echo "Please follow these steps to resolve the conflicts:"
  echo ""
  echo "1. Identify the conflicting files:"
  echo "   - Run 'git status' to see a list of files with conflicts."
  echo ""
  echo "2. Resolve the conflicts:"
  echo "   - Open each conflicting file in a text editor."
  echo "   - Look for conflict markers (<<<<<<<, =======, >>>>>>>) and edit the file to resolve the conflicts."
  echo "   - Save the file after resolving the conflicts."
  echo ""
  echo "3. Stage the resolved files:"
  echo "   - For each file you've resolved, run 'git add <file>' (e.g., 'git add path/to/file.txt')."
  echo "   - You can also use 'git add .' to stage all modified files."
  echo ""
  echo "4. Continue the rebase:"
  echo "   - Run 'git rebase --continue' to continue the rebase process."
  echo ""
  echo "5. If there are more conflicts, repeat steps 1-4."
  echo ""
  echo "6. Once the rebase is complete, force push your changes:"
  echo "   - Run 'git push origin $BRANCH --force' to update the remote branch."
  echo ""
  echo "Alternatively, if you want to abort the rebase and start over, run 'git rebase --abort'."
  exit 1
fi

# Safety check before force pushing
echo "Are you ready to force push to $BRANCH? (y/n)"
read -r confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
  git push origin "$BRANCH" --force
else
  echo "Aborted."
fi
