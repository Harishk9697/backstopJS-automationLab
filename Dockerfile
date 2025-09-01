FROM python:3.10-alpine3.20

COPY . /automation_Robot_app
WORKDIR usr/bin

RUN apk update && \
    apk upgrade --no-cache expat sqlite && \
    apk add --no-cache wget unzip git curl gcc musl-dev python3-dev libffi-dev aws-cli rpm2cpio chromium chromium-chromedriver openjdk11 xmlstarlet jq && \
    python3 -m venv /automation_Robot_app && \
    source /automation_Robot_app/bin/activate

WORKDIR /automation_Robot_app
RUN ls

RUN apk add --no-cache py3-pip && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

RUN chmod +x main_executor.sh

#Default command to execute test
CMD ["./main_executor.sh"]


