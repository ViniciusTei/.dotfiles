#!/bin/bash

# User Menu Interface
echo "==============================="
echo "         SELECT OPTIONS        "
echo "==============================="
echo "1. create_branch.sh"
echo "2. merge_develop.sh"
echo "3. start_env.sh"
echo "==============================="
echo -n "Enter your choice: "
read choice

# Check the user's choice and execute the selected script
case $choice in
  1)
    echo -n "Enter the branch name: "
    read branch

    echo "Executing create_branch.sh..."
    ~/.scripts/create_branch.sh -b $branch
    ;;
  2)
    echo -n "Enter the branch name: "
    read branch

    echo "Executing merge_develop.sh..."
    ~/.scripts/merge_develop.sh -b $branch
    ;;
  3)
    s=$(tmux ls | grep cbrdoc)
    
    if [ -n "$s" ]; then
      echo "Session already exists! Attaching..."
      tmux attach-session -t cbrdoc
    else 
      echo "Executing new session..."
      tmux new-session -s cbrdoc 
    fi
    ;;
  *)
    echo "Invalid choice. Please select option 1 or 2."
    ;;
esac
