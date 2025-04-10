#!/bin/bash

# ANSI escape codes for text formatting
GREEN='\033[0;92m'  # Brighter green
YELLOW='\033[0;93m' # Brighter yellow
RED='\033[0;91m'    # Brighter red
RESET='\033[0m'

# Get the repository root directory
repo_root=$(git rev-parse --show-toplevel)

# Function to get modified files
get_modified_files() {
    git diff HEAD~1 --name-only
}

# Check if pbcopy is available
if ! command -v pbcopy &> /dev/null; then
    printf "${RED}Error: pbcopy is not available. Please install it to use the Grammarly check feature.${RESET}\n"
    exit 1
fi

# Get the modified files before the push
modified_files=$(get_modified_files)

# Check if there are modified files
if [[ -z "$modified_files" ]]; then
    printf "${RED}No modified files found.${RESET}\n"
    git push "$@"
    exit $?
fi

git push "$@"

if [ $? -eq 0 ]; then
    while IFS= read -r file <&3; do  # Read from file descriptor 3
        # Extract filename without path for cleaner output
        filename=$(basename "$file")

        printf "${YELLOW}Did you want to put the contents of ${filename} through Grammarly? (y/n): ${RESET}"
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
            full_path="$repo_root/$file"
            if [[ -f "$full_path" ]]; then
                pbcopy < "$full_path"
                printf "${GREEN}%s content copied to the clipboard${RESET}\n" "$filename"
            else
                printf "${RED}Error: File %s not found. Contents not copied.${RESET}\n" "$filename"
            fi
        fi

    done 3<<< "$modified_files"  # Redirect to file descriptor 3

fi

exit $?