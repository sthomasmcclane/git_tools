#!/bin/bash

# Start the ssh-agent
eval "$(ssh-agent -s)"

# Find all SSH key files in the ~/.ssh folder
ssh_files=(~/.ssh/*)

# Extract only the filenames from the file paths
ssh_files_names=()
for file in "${ssh_files[@]}"; do
    ssh_files_names+=("$(basename "$file")")
done

# Prompt user to select an SSH key file from a numbered list
echo "Select an SSH key file:"
select filename in "${ssh_files_names[@]}"; do
    case "$filename" in
        "") echo "Invalid selection. Please try again.";;
        *) ssh-add "~/.ssh/$filename"
           echo "SSH key $filename added."
           break;;
    esac
done
