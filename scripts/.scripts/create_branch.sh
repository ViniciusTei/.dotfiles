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

echo "Changing to master..."
git fetch
git checkout master
git pull --ff-only
CONFLICTS=$?
if [ $CONFLICTS -ne 0 ] ; then
   echo "There is a conflict. Aborting"
   exit 1
fi

echo "Creating new branch ${branch}"
git checkout -b ${branch}
