#!/bin/bash

cd /vrt
folder_to_cleanup="backstopJS"

if [ -d "$folder_to_cleanup" ]
then
    echo "cleaning up folder $folder_to_cleanup"
    rm -rf "$folder_to_cleanup"
else
    echo "$folder_to_cleanup does not exist."
fi

echo "Cloning Git branch..."
## Clone the Github repository
git clone --single-branch --branch main https://github.com/Harishk9697/backstop-test-suite.git /vrt/backstopJS
if [ $? -ne 0 ]; then
    echo "Command Git clone failed"
fi

echo "change directory to playwright repo"
cd /vrt/backstopJS
echo "list the files"
ls

#echo "Install npm"
## Install dependencies
#npm install

echo "Running reference command..."
## RUN backstop reference
backstop reference --config="backstop.json"
if [ $? -ne 0 ]; then
    echo "Backstop reference command failed"
fi
echo "Running test command..."
## RUN tests
#backstop test --config="backstop.json"
if [ $? -ne 0 ]; then
    echo "Backstop test command failed"
    aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstopJS/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/ --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
else
    echo "Backstop test command passed"
    aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstopJS/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/ --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
fi

## Set variable for clone url
#ARG GITHUB_URL
#ARG BRANCH_NAME
#RUN echo "Git Url: $GITHUB_URL"
#RUN echo "Git Branch name: $BRANCH_NAME"
