#!/bin/bash

# Yellow text variable
YELLOW='\033[0;93m'
RESET='\033[0m' # No Color

if [ $# -eq 0 ]; then
     printf "${YELLOW}Error: No branch name provided.${RESET}\n"
     printf "${YELLOW}Usage: gitout <branch-name>${RESET}\n"
    exit
fi

branch="$1"
printf "${YELLOW}Deleting remote branch '$branch'...${RESET}\n"
git push origin --delete "$branch" && printf "${YELLOW}Remote branch '$branch' deleted.${RESET}\n" || { printf "${YELLOW}Failed to delete remote branch '$branch'.${RESET}\n"; exit 1; }

printf "${YELLOW}Pruning tracking references...${RESET}\n"
git fetch origin --prune && printf "${YELLOW}Tracking references pruned.${RESET}\n" || { printf "${YELLOW}Failed to prune tracking references.${RESET}\n"; exit 1; }

while true; do
  printf "${YELLOW}Deleting local branch '$branch'...${RESET}\n"
  if git branch -d "$branch"; then
    printf "${YELLOW}Local branch '$branch' deleted.${RESET}\n"
    break
  else
    printf "${YELLOW}Local branch '$branch' has unmerged changes.${RESET}\n"
    printf "${YELLOW}Here are the changes:${RESET}\n"
    git diff "$branch"

    read -p "$(printf "${YELLOW}Are you sure you want to delete the branch? (y/n): ${RESET}")" confirm
    case $confirm in
      [Yy]* )
        git branch -D "$branch" && printf "${YELLOW}Local branch '$branch' forcefully deleted.${RESET}\n" || printf "${YELLOW}Failed to delete local branch '$branch'.${RESET}\n"
        break
        ;;
      [Nn]* )
        printf "${YELLOW}Aborted branch deletion.${RESET}\n"
        exit 1
        ;;
      * )
        printf "${YELLOW}Please answer yes or no.${RESET}\n"
        ;;
    esac
  fi
done

