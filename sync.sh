#!/usr/bin/env bash

# 
# Setup automatic sync from a Github upstream repository to a fork
# - a branch "actions" will be created (or re-used) to hold the Github action to run
# - sync is done each hour
# - branch 'actions' needs to be the default branch of your fork (=> settings)
# - the script is able to both create and update and rewrite the sync script if you modify this script file
# 
# Author: Mathiue Carbou
# Date: April 2021
# 
# Notes:
# - Github bug: action is not shown if pushed first before changing the default branch
#
# Good luck...
#
# BLOG: https://blog.mathieu.photography/post/649318432483033088/automatic-fork-syncing-with-github
#

usage() {
  echo "sync.sh <fork> <upstream> <branch-to-sync> <domain>"
  exit 1
}

if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]; then
  usage
fi

fork=$1
upstream=$2
branch=$3
domain="github.com"
tmp_dir=$(mktemp -d -t git)
echo "Temporary directory: $tmp_dir"

if [ "$#" -eq 4 ]; then
  domain=$4
fi

# quic and fast clone
git clone --depth=1 git@$domain:ksuchitra532/$fork.git $tmp_dir

if [ $(git -C $tmp_dir branch --show-current) != "actions" ]; then
  # default repository branch is NOT 'actions'
  git -C $tmp_dir checkout actions
  if [ $? -eq 1 ]
  then
    # branch 'actions' does not exist
    git -C $tmp_dir checkout --orphan actions
    git -C $tmp_dir rm -rf .
    git -C $tmp_dir commit --allow-empty -am "root"
    git -C $tmp_dir push origin actions
  fi
  echo ""
  echo "========================================================"
  echo ">>> WARNING <<<"
  echo "========================================================"
  echo "Please go to: https://$domain/$fork/settings/branches"
  echo "Change your default branch to 'actions'"
  echo "Press a key to continue."
  echo "========================================================"
  read
fi

# create workflow script
mkdir -p $tmp_dir/.github/workflows
cat << EOF > $tmp_dir/.github/workflows/fork-sync.yml
name: "Fork Sync"
on:
  schedule:
    - cron:  '0 */2 * * *'
  workflow_dispatch:
jobs:
  sync-$branch:
    runs-on: ubuntu-latest
    name: "Sync from $upstream@$branch"
    steps:
    - name: "Checkout: $branch"
      uses: actions/checkout@v2
      with:
        ref: $branch
        token: \${{ github.token }}
    - name: "Update: $branch"
      id: sync-$branch
      uses: mathieucarbou/Fork-Sync-With-Upstream-action@fork-sync
      with:
        domain: '$domain'
        upstream_repository: $upstream
        upstream_branch: $branch
        target_branch: $branch
        git_pull_args: --ff-only
        # git_push_args: --force
    - name: Timestamp
      run: date
EOF
git -C $tmp_dir rm .github/workflows/sync.yml # remove old workflow script
git -C $tmp_dir add .github/workflows/fork-sync.yml
git -C $tmp_dir commit -am "fork-sync.yml"
git -C $tmp_dir push origin actions

# cleanup
rm -f -r $tmp_dir/.git
rm -f -r $tmp_dir

echo ""
echo "=========================================================================="
echo ">>> WARNING <<<"
echo "=========================================================================="
echo "Please go to: https://$domain/$fork/actions"
echo "Run the Sync task manually. It will run each hour automatically."
echo "=========================================================================="