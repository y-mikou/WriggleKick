#!/bin/sh
git diff --stat
git add -A
read -p "1行日記をどうぞ: " msg
git commit -m "$msg"
CULLENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
git push origin ${CULLENT_BRANCH}
