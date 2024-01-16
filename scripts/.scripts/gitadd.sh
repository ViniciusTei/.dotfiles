#!/bin/bash

echo "Git diff from > $@"

git diff --color $@ > diff.temp

OFFSET=`cat diff.temp | awk 'BEGIN { FS = "@@"} ; { print $2 }'`

INSERTLINE=`echo $OFFSET | awk -F[=,] '{ print $1 }' | awk -F[=-] '{ print $2 }'`

cat $@ > temp

cat diff.temp 
