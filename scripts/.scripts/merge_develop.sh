#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied! Please enter the branch name"
    exit 1
fi

while getopts b: flag
do
    case "${flag}" in
        b) branch=${OPTARG};;
    esac
done

cd ~/www/cbrdoc/app

echo "Changing to develop..."
git fetch
git checkout develop
git pull --ff-only
echo "Merging ${branch} with develop"
git merge --ff-only ${branch}
CONFLICTS=$?
if [ $CONFLICTS -ne 0 ] ; then
   echo "The merge failed due to clonficts. Try fixing the merge conflicts to continue!"
   exit 1
fi

echo "Merge successful! Pushing changes to origin"
git push
