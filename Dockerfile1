## CentOS 7 base image
FROM ubuntu:latest

USER root
RUN mkdir /vrt
COPY . /vrt
WORKDIR /vrt

RUN apt-get update && \
    apt-get install -y curl unzip git sudo

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
RUN apt-get install -y nodejs

## Install browser
RUN npx @playwright/test install

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
RUN chmod +x test.sh

## Default command to execute playwright test
CMD ["sh", "test.sh"]