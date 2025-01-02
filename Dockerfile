# Use Ubuntu as the base image
FROM ubuntu:20.04

# Copy project files to the container
COPY . /app

# Set the working directory
WORKDIR /app

RUN ls

# Install dependencies
RUN apt-get update && apt-get install -y curl unzip sudo openjdk-11-jdk jq maven && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# Set the default command to execute the script
CMD ["./main_executor.sh"]
