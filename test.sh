#!/bin/bash
## Set variable for clone url
#ARG GITHUB_URL
#ARG BRANCH_NAME
#RUN echo "Git Url: $GITHUB_URL"
#RUN echo "Git Branch name: $BRANCH_NAME"
set -e

try() {
    echo "before clone"
    ## Clone the Github repository
    git clone --single-branch --branch main https://github.com/Harishk9697/playwright-test-suite.git /vrt/backstopJS
    
    echo "change directory to playwright repo"
    cd /vrt/backstopJS

    echo "list the files"
    ls
    
    #echo "Install npm"
    ## Install dependencies
    #npm install
    
    echo "Run reference command"
    ## RUN tests
    backstop reference --config="backstop.json"

    echo "Run test command"
    ## RUN tests
    backstop test --config="backstop.json"

    echo "change directory"
    cd /vrt
    
    ## Copy generated report to s3 bucket
    aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstopJS/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/ --exclude "*/engine_scripts/*"
}

catch() {
    echo "An error occured:"
    echo "$BASH_COMMAND"
    echo "$@"
}

try
catch
