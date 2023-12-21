## Use base image of playwright
FROM mcr.microsoft.com/playwright:v1.24.0-focal AS builder

USER root
RUN mkdir /vrt
COPY . /vrt
WORKDIR /vrt

## Install browser
RUN npx @playwright/test install

## Install dependencies
Run npx playwright install-deps

## CentOS 7 base image
FROM centos:7

COPY --from=builder /vrt /vrt

WORKDIR /vrt

#Update the package manager and install necessary dependencies
RUN yum update -y && yum install -y curl sudo

## Install Node.js
RUN curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
RUN yum install -y nodejs

## Unzip installation
RUN yum install -y unzip

## Install Git
RUN yum install -y git

## Install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip && ./aws/install

## Check version
RUN aws --version

## Install backstopJS
RUN npm install -g backstopjs

## Default command to execute playwright test
CMD ["sh", "test.sh"]