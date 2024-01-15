## CentOS 7 base image
FROM centos:7 AS centos

#COPY --from=builder /vrt /vrt

USER root
RUN mkdir /vrt
COPY . /vrt
WORKDIR /vrt

#Update the package manager and install necessary dependencies
RUN yum update -y && yum install -y curl sudo

## Install Node.js
RUN curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
RUN yum install -y nodejs

## Install Git
RUN yum install -y git

## Use base image of playwright
FROM mcr.microsoft.com/playwright:v1.24.0-focal AS builder

COPY --from=centos /vrt /vrt

WORKDIR /vrt

RUN apt-get update && \
    apt-get install -y curl unzip

#playwright dependencies
RUN npm install

## Install browser
#RUN npx @playwright/test install
RUN npx playwright install

## Install dependencies
Run npx playwright install-deps

## Install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip && ./aws/install

## Check version
RUN aws --version

## Install backstopJS
RUN npm install -g backstopjs

## Make the script executable
RUN chmod +x test2.sh

## Default command to execute playwright test
CMD ["sh", "test3.sh"]