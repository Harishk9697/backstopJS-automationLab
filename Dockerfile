# Use Ubuntu as the base image
FROM python:3.10-alpine3.21

# Copy project files to the container
COPY . /app

# Set the working directory
WORKDIR /app

RUN ls

# Install dependencies
RUN apt-get update && apt-get install -y curl unzip sudo && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install
    
RUN apk add --no-cache py3-pip && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt
    
RUN chmod +x main_executor.sh

# Set the default command to execute the script
CMD ["./main_executor.sh"]
