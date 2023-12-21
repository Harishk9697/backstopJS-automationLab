## Use base image of playwright
#FROM mcr.microsoft.com/playwright:v1.24.0-focal AS builder

#USER root
#RUN mkdir /vrt
#COPY . /vrt
#WORKDIR /vrt

## Install browser
#RUN npx @playwright/test install

## Install dependencies
#Run npx playwright install-deps

## CentOS 7 base image
FROM centos:7

#COPY --from=builder /vrt /vrt
#COPY --from=builder /ms-playwright /ms-playwright

USER root
RUN mkdir /vrt
COPY . /vrt
WORKDIR /vrt

#Update the package manager and install necessary dependencies
RUN yum update -y && yum install -y curl sudo

## Install Node.js
RUN curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
RUN yum install -y nodejs

## Install browser
RUN npx @playwright/test install

## Install chromium browser dependencies
RUN yum update -y && \
    yum install -y alsa-lib \
    at-spi2-atk  \
    at-spi2-core \
    atk \
    bash \
    cairo \
    cups-libs \
    dbus-libs \
    expat \
    flac-libs \
    gdk-pixbuf2 \
    glib2 \
    glibc \
    gtk3 \
    libX11 \
    libXcomposite \
    libXdamage \
    libXext \
    libXfixes \
    libXrandr \
    libXtst \
    libcanberra-gtk3 \
    libdrm \
    libgcc \
    libstdc++ \
    libxcb \
    libxkbcommon \
    libxshmfence \
    libxslt \
    mesa-libgbm \
    nspr \
    nss \
    nss-util \
    pango \
    policycoreutils \
    policycoreutils-python-utils \
    zlib

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

## Make the script executable
RUN chmod +x test.sh

## Default command to execute playwright test
CMD ["sh", "test.sh"]