#!/bin/bash

cd /vrt
folder_to_cleanup="backstopJS"

if [ -d "$folder_to_cleanup" ]
then
    echo "cleaning up folder $folder_to_cleanup"
    rm -rf "$folder_to_cleanup"
    mkdir backstopJS
else
    echo "$folder_to_cleanup does not exist."
    mkdir backstopJS
fi

echo "change directory to playwright repo"
cd backstopJS
echo "list the files"
ls

echo "Cloning Git branch..."
## Clone the Github repository
#git clone --single-branch --branch main https://github.com/Harishk9697/backstop-test-suite.git /vrt/backstopJS
aws s3 cp --acl bucket-owner-full-control --recursive s3://tf-rf-scripts-spe-qaqc-bucket/SPT_VRT/aut-vrt-spt/ .
if [ $? -ne 0 ]; then
    echo "Command Git clone failed"
fi

backstop init
cp -r ./Director_Diverse/backstop_data/engine_scripts ./backstop_data/


#echo "Install npm"
## Install dependencies
#npm install

echo "Running reference command..."
## RUN backstop reference
backstop reference --config="./Director_Diverse/backstop.json"
#backstop reference --config="backstop.json"
if [ $? -ne 0 ]; then
    echo "Backstop reference command failed"
fi
Sleep 5
echo "Running test command..."
## RUN tests
backstop test --config="./Director_Diverse/backstop.json"
if [ $? -ne 0 ]; then
    echo "Backstop test command failed"
    Sleep 5
    aws s3 cp --acl bucket-owner-full-control --recursive ./backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/Director_Diverse --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
else
    echo "Backstop test command passed"
    Sleep 5
    aws s3 cp --acl bucket-owner-full-control --recursive ./backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/Director_Diverse --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
fi

#aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstopJS/BrandsPortal/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/Backstop_JS_SPT_report/ --exclude "engine_scripts/*"
## Set variable for clone url
#ARG GITHUB_URL
#ARG BRANCH_NAME
#RUN echo "Git Url: $GITHUB_URL"
#RUN echo "Git Branch name: $BRANCH_NAME"
