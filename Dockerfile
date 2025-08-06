##Use base image of playwright
FROM mcr.microsoft.com/playwright:v1.51.0-jammy


WORKDIR /playwright

RUN apt-get update || apt-get update && \
    apt-get install -y curl unzip sudo=1.9.9-1ubuntu2.5 openjdk-11-jdk jq xmlstarlet iputils-ping || apt-get install -y curl unzip sudo openjdk-11-jdk jq xmlstarlet  iputils-ping && \
    curl -sL https://deb.nodesource.com/setup_22.x | sudo bash -  && \
    apt-get install -y nodejs  && \
    npx playwright install-deps || npx playwright install-deps  && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    ls /playwright && ls /ms-playwright && \
    chmod +x /ms-playwright/chromium-*/chrome-linux/chrome 
    
# Download Oracle Instant Client for Linux
RUN curl https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basic-linux.x64-21.9.0.0.0dbru.zip -o "oracle-client.zip" && \
    # Unzip the Oracle Client into /usr/lib/oracle
    unzip oracle-client.zip -d /usr/lib/oracle && \
    # Ensure the directory is named correctly
    test -d /usr/lib/oracle/instantclient_21_9 || mv /usr/lib/oracle/instantclient_21_* /usr/lib/oracle/instantclient_21_9 && \
    # Create symbolic links for Oracle libraries, overwriting if they already exist
    ln -sf /usr/lib/oracle/instantclient_21_9 /usr/lib/oracle/instantclient && \
    ln -sf /usr/lib/oracle/instantclient_21_9/libclntsh.so.21.1 /usr/lib/oracle/instantclient/libclntsh.so && \
    ln -sf /usr/lib/oracle/instantclient_21_9/libocci.so.21.1 /usr/lib/oracle/instantclient/libocci.so && \
    # Clean up the downloaded zip file
    rm -rf oracle-client.zip
    
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install playwright@1.51.0 --save-dev

# Install Aspera Connect from tar.gz
RUN curl -L -o ibm-aspera-connect.tar.gz "https://d3gcli72yxqn2z.cloudfront.net/downloads/connect/latest/bin/ibm-aspera-connect_4.2.16.884-HEAD_linux_x86_64.tar.gz" \
    && tar -xzf ibm-aspera-connect.tar.gz -C /opt \
    && rm ibm-aspera-connect.tar.gz
    
RUN chmod +x main_executor.sh

## Default command to execute test
CMD ["./main_executor.sh"]


