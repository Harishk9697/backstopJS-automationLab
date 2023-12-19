## CentOS 7 base image
FROM centos:7

## Install Node.js
#RUN curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
#RUN yum install -y nodejs
RUN yum update -y && yum install -y \
    git npm nodejs

## Install backstopJS
RUN npm install -g backstopjs

## Install Git
RUN apt-get update && apt-get install -y git

RUN mkdir /vrt
COPY . /vrt
WORKDIR /vrt

## Set variable for clone url
ARG GITHUB_URL
ARG BRANCH_NAME
RUN echo "Git Url: $GITHUB_URL"
RUN echo "Git Branch name: $BRANCH_NAME"
## Clone the Github repository
Run git clone --single-branch --branch $BRANCH_NAME $GITHUB_URL /vrt

WORKDIR /vrt

## RUN refernce command
RUN backstop reference
## RUN test command
Run backstop test