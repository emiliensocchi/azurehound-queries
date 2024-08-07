#!/bin/bash

## Stage 0 ##############################################################

set -e
set -x

echo "Merging queries"
bash ./.github/actions/merge-cypher-queries/scripts/merge-cypher-queries.sh

## Stage 1 ##############################################################

echo "Committing changes"

if [[ -z "$INPUT_USER_EMAIL" ]]
then
  echo 'Email for the git commit must be defined'
  return 1
fi

if [[ -z "$INPUT_USER_NAME" ]]
then
  echo 'Github username for the git commit must be defined'
  return 1
fi

GIT_SERVER='github.com'
DESTINATION_BRANCH='main'

git config --global --add safe.directory /github/workspace
git config --global user.email "$INPUT_USER_EMAIL"
git config --global user.name "$INPUT_USER_NAME"

git add .
if git status | grep -q "Changes to be committed"
then
  git commit --message "Merge queries"
  git push -u origin HEAD:"$DESTINATION_BRANCH"
  echo "Pushing commit repository"
else
  echo "No changes detected"
fi