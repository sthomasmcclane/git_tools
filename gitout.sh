#!/bin/bash

# Color variables
YELLOW='\033[0;93m'
RED='\033[0;91m'
GREEN='\033[0;92m'
RESET='\033[0m'

# Protected branches array
protected_branches=("master" "main" "documentation-public")

# Function to check if a branch is protected
is_protected_branch() {
  local branch="$1"
  for protected_branch in "${protected_branches[@]}"; do
    if [[ "$branch" == "$protected_branch" ]]; then
      return 0 # Protected branch found
    fi
  done
  return 1 # Not a protected branch
}

# Function to check for unpushed commits
check_unpushed_commits() {
  local branch="$1"
  local unpushed_count=$(git cherry -v | wc -l)
  if [[ "$unpushed_count" -gt 0 ]]; then
    echo -e "${YELLOW}Unpushed commits found on branch '$branch':${RESET}"
    git cherry -v
    return 1
  else
    return 0
  fi
}

# Function to check for untracked files
check_untracked_files() {
  local branch="$1"
  local untracked_files=$(git status --porcelain | grep "^??" | wc -l)
  if [[ "$untracked_files" -gt 0 ]]; then
    echo -e "${YELLOW}Untracked files found on branch '$branch':${RESET}"
    git status --porcelain | grep "^??"
    return 1
  else
    return 0
  fi
}

# Main script execution
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No branch name provided.${RESET}"
  echo -e "${YELLOW}Usage: gitout <branch-name>${RESET}"
  exit 1
fi

branch="$1"

# Check if branch is protected
if is_protected_branch "$branch"; then
  echo -e "${RED}Error: The branch '$branch' is protected and cannot be deleted using this script.${RESET}"
  exit 1
fi

#Check if branch exists
if ! git show-branch "remotes/origin/$branch" &> /dev/null; then
  echo -e "${RED}Error: Remote branch '$branch' does not exist.${RESET}"
  exit 1
fi

echo -e "${YELLOW}You are about to delete the branch '$branch' both remotely and locally.${RESET}"

# Confirm remote deletion
read -p "$(echo -e "${YELLOW}Are you sure you want to delete the remote branch '$branch'? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_remote
if [[ -z "$confirm_remote" ]]; then
  echo -e "${YELLOW}Deleting remote branch '$branch'...${RESET}"
  git push origin --delete "$branch" && echo -e "${GREEN}Remote branch '$branch' deleted.${RESET}" || { echo -e "${RED}Failed to delete remote branch '$branch'.${RESET}"; exit 1; }
else
  echo -e "${YELLOW}Remote branch deletion aborted.${RESET}"
  exit 0
fi

echo -e "${YELLOW}Pruning tracking references...${RESET}"
git fetch origin --prune && echo -e "${GREEN}Tracking references pruned.${RESET}" || { echo -e "${RED}Failed to prune tracking references.${RESET}"; exit 1; }

# Check for unpushed commits
if check_unpushed_commits "$branch"; then
  echo -e "${YELLOW}Warning: There are unpushed commits on this branch.${RESET}"
fi

# Check for untracked files
if check_untracked_files "$branch"; then
  echo -e "${YELLOW}Warning: There are untracked files on this branch.${RESET}"
fi

while true; do
  echo -e "${YELLOW}Deleting local branch '$branch'...${RESET}"
  if git branch -d "$branch"; then
    echo -e "${GREEN}Local branch '$branch' deleted.${RESET}"
    break
  else
    echo -e "${YELLOW}Local branch '$branch' has unmerged changes.${RESET}"
    echo -e "${YELLOW}Here are the changes:${RESET}"
    git diff "$branch"
    read -p "$(echo -e "${YELLOW}Are you sure you want to forcefully delete the local branch '$branch'? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_force
    if [[ -z "$confirm_force" ]]; then
      git branch -D "$branch" && echo -e "${GREEN}Local branch '$branch' forcefully deleted.${RESET}" || echo -e "${RED}Failed to delete local branch '$branch'.${RESET}"
      break
    else
      echo -e "${YELLOW}Local branch deletion aborted.${RESET}"
      exit 0
    fi
  fi
done
