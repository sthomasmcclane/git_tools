#!/usr/bin/env bash

# Display help message
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: gitit <branch-name | branch-number | main | public>"
  echo "  Checks out the specified branch with the following enhancements:"
  echo "  - If <branch-name> is a number, it prepends 'C4E-'."
  echo "  - If <branch-name> is 'main', it checks out 'main' or 'master'."
  echo "  - If <branch-name> is 'public', it checks out 'documentation-public'."
  echo "  - Otherwise, it attempts to check out the branch as is."
  exit 0
fi

# Check if a branch name is provided
if [ -z "$1" ]; then
  echo "No branch name provided. Performing 'git pull'."
  if git pull; then
    exit 0
  else
    echo "Error: Git pull failed." >&2
    exit 1
  fi
fi

branch_to_checkout="$1"
original_input="$1" # Keep original input for error messages

# Check if the input is a number (assuming it's a C4E ticket number)
if [[ "$branch_to_checkout" =~ ^[0-9]+$ ]]; then
  branch_to_checkout="C4E-$branch_to_checkout"
elif [[ "$branch_to_checkout" == "main" || "$branch_to_checkout" == "master" ]]; then
  # Check for 'main' or 'master'
  if git rev-parse --verify --quiet "main"; then
    branch_to_checkout="main"
  elif git rev-parse --verify --quiet "master"; then
    branch_to_checkout="master"
  else
    echo "Error: Neither 'main' nor 'master' branch exists in this repository." >&2
    exit 1
  fi
elif [[ "$branch_to_checkout" == "public" ]]; then
  branch_to_checkout="documentation-public"
fi

# Attempt to checkout the branch
if git rev-parse --verify --quiet "$branch_to_checkout"; then
  if git checkout "$branch_to_checkout"; then
    echo "Switched to branch '$branch_to_checkout'"
    exit 0
  else
    echo "Error: Failed to checkout branch '$branch_to_checkout'." >&2
    exit 1
  fi
else
  # If branch doesn't exist and input was a number, create the branch
  if [[ "$original_input" =~ ^[0-9]+$ ]]; then
    echo "Branch '$branch_to_checkout' does not exist. Creating it..."
    if git checkout -b "$branch_to_checkout"; then
      echo "Created and switched to branch '$branch_to_checkout'"
      exit 0
    else
      echo "Error: Failed to create branch '$branch_to_checkout'." >&2
      exit 1
    fi
  else
    echo "Error: Branch '$original_input' (resolved to '$branch_to_checkout') does not exist." >&2
    exit 1
  fi
fi
