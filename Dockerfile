## CentOS 7 base image
FROM centos:7

#Update the package manager and install necessary dependencies
RUN yum update -y && yum install -y curl sudo

## Install Node.js
RUN curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
RUN yum install -y nodejs
#RUN yum update -y && yum install -y \
#    git npm nodejs

## Install awscli
RUN yum install -y awscli

## awscli version check
RUN aws --version

## Install backstopJS
RUN npm install -g backstopjs

## Install Git
RUN yum install -y git

RUN mkdir /vrt
#COPY . /vrt
WORKDIR /vrt

## Set variable for clone url
ARG GITHUB_URL
ARG BRANCH_NAME
RUN echo "Git Url: $GITHUB_URL"
RUN echo "Git Branch name: $BRANCH_NAME"
## Clone the Github repository
Run git clone --single-branch --branch $BRANCH_NAME $GITHUB_URL /vrt

WORKDIR /vrt

## Download browsers
Run npx playwright install

## List the files
RUN ls /vrt/backstop_data

## RUN refernce command
RUN backstop reference --config="backstop.json"
## RUN test command
Run backstop test --config="backstop.json"

## List the files
RUN ls /vrt/backstop_data

## Copy generated references to s3 bucket
#RUN aws s3 cp /vrt/backstop_data/bitmaps_reference s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/

## Copy generated test images to s3 bucket
#RUN aws s3 cp /vrt/backstop_data/bitmaps_test s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/

## Copy generated html report to s3 bucket
#RUN aws s3 cp /vrt/backstop_data/html_report s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/

RUN aws s3 cp --acl bucket-owner-full-control --recursive /vrt/backstop_data s3://tf-rf-scripts-spe-qaqc-bucket/BackstopJSReport/ --exclude "*/engine_scripts/*"