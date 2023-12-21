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
    yum install -y alsa-lib-0:1.2.3.2-1.el8.x86_64 \
    at-spi2-atk-0:2.26.2-1.el8.x86_64  \
    at-spi2-core-0:2.28.0-1.el8.x86_64 \
    atk-0:2.28.1-1.el8.x86_64          \
    bash-0:4.4.19-12.el8.x86_64        \
    cairo-0:1.15.12-3.el8.x86_64       \
    cups-libs-1:2.2.6-38.el8.x86_64    \
    dbus-libs-1:1.12.8-12.el8_3.x86_64 \
    expat-0:2.2.5-4.el8.x86_64 \
    flac-libs-0:1.3.2-9.el8.x86_64 \
    gdk-pixbuf2-0:2.36.12-5.el8.x86_64 \
    glib2-0:2.56.4-8.el8.x86_64 \
    glibc-0:2.28-127.el8.x86_64 \
    gtk3-0:3.22.30-6.el8.x86_64 \
    libX11-0:1.6.8-3.el8.x86_64 \
    libXcomposite-0:0.4.4-14.el8.x86_64 \
    libXdamage-0:1.1.4-14.el8.x86_64 \
    libXext-0:1.3.4-1.el8.x86_64 \
    libXfixes-0:5.0.3-7.el8.x86_64 \
    libXrandr-0:1.5.2-1.el8.x86_64 \
    libXtst-0:1.2.3-7.el8.x86_64 \
    libcanberra-gtk3-0:0.30-16.el8.x86_64 \
    libdrm-0:2.4.101-1.el8.x86_64 \
    libgcc-0:8.3.1-5.1.el8.x86_64 \
    libstdc++-0:8.3.1-5.1.el8.x86_64 \
    libxcb-0:1.13.1-1.el8.x86_64 \
    libxkbcommon-0:0.9.1-1.el8.x86_64 \
    libxshmfence-0:1.3-2.el8.x86_64 \
    libxslt-0:1.1.32-5.el8.x86_64 \
    mesa-libgbm-0:20.1.4-1.el8.x86_64 \
    nspr-0:4.25.0-2.el8_2.x86_64 \
    nss-0:3.53.1-17.el8_3.x86_64 \
    nss-util-0:3.53.1-17.el8_3.x86_64 \
    pango-0:1.42.4-6.el8.x86_64 \
    policycoreutils-0:2.9-9.el8.x86_64 \
    policycoreutils-python-utils-0:2.9-9.el8.noarch \
    zlib-0:1.2.11-16.2.el8_3.x86_64

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