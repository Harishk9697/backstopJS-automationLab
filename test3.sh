#!/bin/bash

cd /vrt

backstop init
#cp -r ./BrandsPortal/backstop_data/engine_scripts ./backstop_data/

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

#echo "change directory to playwright repo"
#cd backstopJS
echo "list the files"
ls

echo "Cloning Git branch..."
## Clone the Github repository
#git clone --single-branch --branch main https://github.com/Harishk9697/backstop-test-suite.git /vrt/backstopJS
aws s3 cp --acl bucket-owner-full-control --recursive s3://internationalportals/aut-vrt-ip/ ./backstopJS
if [ $? -ne 0 ]; then
    echo "Command Git clone failed"
fi

cp -r /vrt/backstopJS/backstop_data/engine_scripts ./backstop_data/
#echo "Install npm"
## Install dependencies
#npm install
for folder in /vrt/backstopJS/BackstopJS_JSON_Files/Firefox/*/; do
    #cp -r $folder/backstop_data/engine_scripts ./backstop_data/
    folder_name=$(basename "$folder")
    echo "Folder name is: $folder_name"
    echo "Running reference command..."
    ## RUN backstop reference
    backstop reference --config="$folder/$folder_name.json"
    #backstop reference --config="backstop.json"
    if [ $? -ne 0 ]; then
        echo "Backstop reference command failed"
    fi
    sleep 5
    echo "Running test command..."
    ## RUN tests
    backstop test --config="$folder/$folder_name.json"
    if [ $? -ne 0 ]; then
        echo "Backstop test command failed"
        sleep 5
        aws s3 cp --acl bucket-owner-full-control --recursive ./backstop_data s3://internationalportals/aut-vrt-ip/IP_Firefox_report/$folder_name --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
    else
        echo "Backstop test command passed"
        sleep 5
        aws s3 cp --acl bucket-owner-full-control --recursive ./backstop_data s3://internationalportals/aut-vrt-ip/IP_Firefox_report/$folder_name --exclude "engine_scripts/*" && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
    fi
done

#aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstopJS/BrandsPortal/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/Backstop_JS_SPT_report/ --exclude "engine_scripts/*"
## Set variable for clone url
#ARG GITHUB_URL
#ARG BRANCH_NAME
#RUN echo "Git Url: $GITHUB_URL"
#RUN echo "Git Branch name: $BRANCH_NAME"
