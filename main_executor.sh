#!/bin/bash

# Variables
PROJECT_NAME="SPConnectAppium"
DEVICE_POOL_NAME="pixel 4a"
TEST_SPEC_NAME="androidTestNGXML.yml"
S3_BUCKET="tf-rf-scripts-spe-qaqc-bucket/SPConnect_App"
APK_FILE="app-release.apk"
DEPENDENCY_ZIP="zip-with-dependencies.zip"
#IPA_FILE="path/to/your.ipa"

echo "Copy Project from S3"
aws s3 cp --recursive s3://$S3_BUCKET/SP_Connect_Repo/aut-appiumjava-connect/ .
ls

# Create a zip test package
echo "Creating zip test package..."
mvn clean package -DskipTests=true

ls

PROJECT_ARN=$(aws devicefarm list-projects --query "projects[?name=='$PROJECT_NAME'].arn" --output text)
echo "Project arn is : $PROJECT_ARN"

# Download APK/IPA from S3
echo "Downloading Zip from S3 and uploading to Device Farm..."
aws s3 cp s3://$S3_BUCKET/$DEPENDENCY_ZIP .

# Upload the package to Device Farm
echo "Uploading test package to Device Farm..."
TEST_PACKAGE_UPLOAD=$(aws devicefarm create-upload --project-arn "$PROJECT_ARN" --name "$DEPENDENCY_ZIP" --type "APPIUM_JAVA_TESTNG_TEST_PACKAGE")
TEST_PACKAGE_UPLOAD_ARN=$(echo $TEST_PACKAGE_UPLOAD | jq -r '.upload.arn')
TEST_PACKAGE_UPLOAD_URL=$(echo $TEST_PACKAGE_UPLOAD | jq -r '.upload.url')
echo "Test Package Upload arn is : $TEST_PACKAGE_UPLOAD_ARN"

curl -T $DEPENDENCY_ZIP $TEST_PACKAGE_UPLOAD_URL

# Download APK/IPA from S3
echo "Downloading APK/IPA from S3 and uploading to Device Farm..."
aws s3 cp s3://$S3_BUCKET/$APK_FILE .

# Upload the APK or IPA to Device Farm
echo "Uploading APK/IPA file to Device Farm..."
APP_UPLOAD=$(aws devicefarm create-upload --project-arn "$PROJECT_ARN" --name "$APK_FILE" --type "ANDROID_APP")
APP_UPLOAD_ARN=$(echo $APP_UPLOAD | jq -r '.upload.arn')
APP_UPLOAD_URL=$(echo $APP_UPLOAD | jq -r '.upload.url')

curl -T $APK_FILE $APP_UPLOAD_URL

# Wait for the uploads to succeed
while true; do
    APP_UPLOAD_STATUS=$(aws devicefarm get-upload --arn $APP_UPLOAD_ARN | jq -r '.upload.status')
    echo "App Upload status is: $APP_UPLOAD_STATUS"
    TEST_UPLOAD_STATUS=$(aws devicefarm get-upload --arn $TEST_PACKAGE_UPLOAD_ARN | jq -r '.upload.status')
    echo "Test Package Upload status is: $TEST_UPLOAD_STATUS"
    if [[ "$APP_UPLOAD_STATUS" == "SUCCEEDED" && "$TEST_UPLOAD_STATUS" == "SUCCEEDED" ]]; then
        break
    elif [[ "$APP_UPLOAD_STATUS" == "FAILED" || "$TEST_UPLOAD_STATUS" == "FAILED" ]]; then
        echo "Upload failed"
        exit 1
    else
        echo "Waiting for uploads to complete..."
        sleep 10
    fi
done

# Fetch the ARN of the test spec
echo "Fetching ARN of the test spec..."
TEST_SPEC_ARN=$(aws devicefarm list-uploads --arn "$PROJECT_ARN" --query "uploads[?name=='$TEST_SPEC_NAME'].arn" --output text)
echo "Test spec arn is: $TEST_SPEC_ARN"

# Fetch the ARN of the device pool
echo "Fetching ARN of the device pool..."
DEVICE_POOL_ARN=$(aws devicefarm list-device-pools --arn "$PROJECT_ARN" --query "devicePools[?name=='$DEVICE_POOL_NAME'].arn" --output text)
echo "Device Pool arn is: $DEVICE_POOL_ARN"

export TZ=Asia/Kolkata

current_datetime=$(date +'%Y-%m-%d_%H:%M:%S')

# Schedule the run
echo "Scheduling the run..."
RUN=$(aws devicefarm schedule-run --project-arn "$PROJECT_ARN" --app-arn "$APP_UPLOAD_ARN" --device-pool-arn "$DEVICE_POOL_ARN" --name "TestRun_$current_datetime" --test testSpecArn="$TEST_SPEC_ARN",type=APPIUM_JAVA_TESTNG,testPackageArn="$TEST_PACKAGE_UPLOAD_ARN")

echo "Run scheduled successfully!"

RUN_ARN=$(echo $RUN | jq -r '.run.arn')

# Wait for the test run to complete
echo "Waiting for the test run to complete..."
while true; do
    RUN_STATUS=$(aws devicefarm get-run --arn $RUN_ARN | jq -r '.run.status')
    if [[ "$RUN_STATUS" == "COMPLETED" ]]; then
        break
    elif [[ "$RUN_STATUS" == "ERRORED" || "$RUN_STATUS" == "FAILED" ]]; then
        echo "Test run failed"
        exit 1
    else
        echo "Waiting for test run to complete..."
        sleep 30
    fi
done

# Fetch the test report
echo "Fetching the test report..."
REPORT_URL=$(aws devicefarm get-run --arn $RUN_ARN | jq -r '.run.resultUrl')

# Download the test report
echo "Downloading the test report..."
curl -o test-report.zip $REPORT_URL

# Upload the test report to S3
echo "Uploading the test report to S3..."
aws s3 cp test-report.zip s3://$S3_BUCKET/test-report_$current_datetime.zip
