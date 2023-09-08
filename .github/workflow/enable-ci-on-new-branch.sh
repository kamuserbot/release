#!/usr/bin/env bash

## this script assumes that, the user knows for which branch user wants to run the scirpt for

#get the gitops branch name you want to enable openshit-ci on
GITOPS_BRANCH=${GITOPS_BRANCH:-"V1.10"}

# copy master files from the main directory and updating the branch details
cd ci-operator/config/redhat-developer/gitops-operator/
ls redhat-developer-gitops-operator-master* >/tmp/tmpfile
while read -r filename; do
    destination=$(echo $filename | sed "s/master/$GITOPS_BRANCH/g")
    ## copy to temporary file
    TEMP_FILE="/tmp/gitops-tmep-$RANDOM.yaml"
    cp $filename $TEMP_FILE
    yq 'del(.tests[] | select(.as == "periodic-kuttl-sequential"))' $TEMP_FILE | yq 'del(.tests[] | select(.as == "periodic-kuttl-parallel"))' | sed "s/master/$GITOPS_BRANCH/g" >$destination
done </tmp/tmpfile

## going back to root directory
cd - 

# add entry to config file
CONFIG_ENTRY="      - redhat-developer-gitops-operator-$GITOPS_BRANCH-presubmits.yaml"
CONFIG_FILE="core-services/sanitize-prow-jobs/_config.yaml"

lineStr=$(grep -n 'redhat-developer-gitops-operator-master-presubmits.yaml' ./$CONFIG_FILE)
IFS_BACKUP=$IFS
IFS=':'
read -ra LineNo <<<"$lineStr"
IFS=$IFS_BACKUP

{
    head -n $LineNo ./$CONFIG_FILE
    echo "$CONFIG_ENTRY"
    tail -n +$(expr $LineNo + 1) ./$CONFIG_FILE
} >/tmp/out
cat /tmp/out > $CONFIG_FILE
