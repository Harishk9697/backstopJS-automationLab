# Use Ubuntu as the base image
FROM python:3.10-alpine3.21

# Copy project files to the container
COPY . /app

# Set the working directory
WORKDIR /app

RUN ls

# Install dependencies
RUN apk update && \
    apk add --no-cache wget unzip git curl gcc musl-dev python3-dev libffi-dev aws-cli rpm2cpio openjdk11 && \
    python3 -m venv /app && \
    source /app/bin/activate

WORKDIR /app
RUN ls   

RUN apk add --no-cache py3-pip && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt
    
RUN chmod +x main_executor.sh

# Set the default command to execute the script
CMD ["./main_executor.sh"]
