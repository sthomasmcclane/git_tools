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
  for protected_branch in "${protected_branches[@]}";
  do
    if [[ "$branch" == "$protected_branch" ]]; then
      return 0 # Protected branch found
    fi
  done
  return 1 # Not a protected branch
}

# Function to check for untracked files
check_untracked_files() {
  local branch="$1"
  local untracked_files=$(git status --porcelain | grep "^??" | wc -l)
  if [[ "$untracked_files" -gt 0 ]]; then
    echo -e "${YELLOW}Untracked files found on branch '$branch':${RESET}"
    git status --porcelain |
    grep "^??"
    return 1
  else
    return 0
  fi
}

# Function to check for a clean working directory
is_working_directory_clean() {
  if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: Uncommitted changes found in the working directory.${RESET}"
    git status
    return 1
  fi
  return 0
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

# Refresh remote information
echo -e "${YELLOW}Refreshing remote tracking information...${RESET}"
git fetch origin --prune

# Check for remote branch existence
if git show-branch "remotes/origin/$branch" &> /dev/null; then
  echo -e "${YELLOW}Remote branch 'origin/$branch' found.${RESET}"
  echo -e "${YELLOW}Since it is standard practice to delete feature branches on merge at your company, it is likely this remote branch has already been deleted or scheduled for deletion.${RESET}"
  echo -e "${YELLOW}Please check the merge status and delete the branch in GitLab if needed, or if the merge failed, complete the merge.${RESET}"
  echo -e "${YELLOW}If you would still like to attempt to delete it, you can run this command:${RESET}"
  echo -e "${YELLOW}git push origin --delete $branch${RESET}"
  exit 0
fi

echo -e "${YELLOW}You are about to clean up the local branch '$branch'.${RESET}"
read -p "$(echo -e "${YELLOW}Continue? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_continue
if [[ -n "$confirm_continue" ]]; then
  echo -e "${YELLOW}Aborting.${RESET}"
  exit 0
fi

# Check for untracked files
if check_untracked_files "$branch"; then
  echo -e "${YELLOW}Warning: There are untracked files on this branch.${RESET}"
  read -p "$(echo -e "${YELLOW}Continue anyway? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_continue
  if [[ -n "$confirm_continue" ]]; then
    echo -e "${YELLOW}Aborting.${RESET}"
    exit 0
  fi
}

while true; do
  echo -e "${YELLOW}Deleting local branch '$branch'...${RESET}"
  read -p "$(echo -e "${YELLOW}Continue? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_continue
  if [[ -n "$confirm_continue" ]]; then
    echo -e "${YELLOW}Aborting.${RESET}"
    exit 0
  fi
  if git branch -d "$branch"; then
    echo -e "${GREEN}Local branch '$branch' deleted.${RESET}"
    break
  else
    echo -e "${YELLOW}Local branch '$branch' has unmerged changes.${RESET}"
    echo -e "${YELLOW}Here are the changes:${RESET}"
    git log --oneline --graph "$branch" ^"main" # or "master"
    git status -b -s
    read -p "$(echo -e "${YELLOW}Are you sure you want to forcefully delete the local branch '$branch'? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_force
    if [[ -n "$confirm_force" ]]; then
      echo -e "${YELLOW}Aborting.${RESET}"
      exit 0
    fi
    git branch -D "$branch" && echo -e "${GREEN}Local branch '$branch' forcefully deleted.${RESET}" ||
    echo -e "${RED}Failed to delete local branch '$branch'.${RESET}"
    break
  fi
done

echo -e "${YELLOW}Pruning tracking references...${RESET}"
read -p "$(echo -e "${YELLOW}Continue? (Press Enter to continue, any other key to abort): ${RESET}")" confirm_continue
if [[ -n "$confirm_continue" ]]; then
  echo -e "${YELLOW}Aborting.${RESET}"
  exit 0
fi
git fetch origin --prune && echo -e "${GREEN}Tracking references pruned.${RESET}" ||
{
  echo -e "${RED}Failed to prune tracking references.${RESET}"
  exit 1
}

echo -e "${GREEN}Branch cleanup complete.${RESET}"
exit 0