FROM python:3.10-alpine3.20

COPY . /automation_Robot_app
WORKDIR /automation_Robot_app

RUN apk update && \
    apk upgrade --no-cache expat sqlite && \
    apk add --no-cache wget unzip git curl gcc musl-dev python3-dev libffi-dev aws-cli rpm2cpio chromium chromium-chromedriver openjdk11 xmlstarlet jq && \
    python3 -m venv /automation_Robot_app && \
    source /automation_Robot_app/bin/activate

RUN ls

RUN apk add --no-cache py3-pip && \
    pip install --upgrade pip && \
    pip install --no-cache-dir robotframework==7.2.2
    pip install --no-cache-dir wheel==0.37.0
    pip install --no-cache-dir robotframework-selenium2library==3.0.0
    pip install --no-cache-dir robotframework-seleniumlibrary==5.1.3
    pip install --no-cache-dir selenium==4.9.0
    pip install --no-cache-dir setuptools==47.1.0
    pip install --no-cache-dir robotframework-databaseLibrary==1.0.1
    pip install --no-cache-dir robotframework-requests
    pip install --no-cache-dir robotframework-pabot
    pip install --no-cache-dir autoit
    pip install --no-cache-dir pyautoit

WORKDIR /automation_Robot_app
RUN ls

RUN pwd

RUN chmod +x main_executor.sh

#Default command to execute test
CMD ["main_executor.sh"]





