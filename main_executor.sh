#!/bin/bash

# Variables
PROJECT_NAME="SPConnectAppium"
browser="Google_Pixel_8_14"
environment="android"
DEVICE_POOL_NAME=$browser
S3_BUCKET="s3://tf-rf-scripts-spe-qaqc-bucket/SPConnect_App"
APK_FILE="app-release.apk"
IPA_FILE="SPConnect.ipa"
DEPENDENCY_ZIP="zip-with-dependencies.zip"

echo "Copy Project from S3"
aws s3 cp s3://tf-rf-scripts-spe-qaqc-bucket/SP_Connect_Repo/ . --recursive && echo "Copied from s3 bucket" || echo "Copy from s3 bucket failed"
ls

passed_testcases=0
failed_testcases=0
skipped_testcases=0

# Determine platform and manufacturer based on environment
if [ "$environment" == "ios" ]; then
    PLATFORM_VALUE="IOS"
    MANUFACTURER_VALUE="Apple"
    YML_FILE="iostestspec.yml"
    TESTNG_XML_FILE="ios_modules_testng.xml"
    S3_BUCKET_File_Path="$S3_BUCKET/SPConnect.ipa"
    APP_FILE_NAME=$IPA_FILE
    APP_TYPE="IOS_APP"
elif [ "$environment" == "android" ]; then
    PLATFORM_VALUE="ANDROID"
    MANUFACTURER_VALUE="Google"
    YML_FILE="androidtestspec.yml"
    TESTNG_XML_FILE="android_modules_testng.xml"
    S3_BUCKET_File_Path="$S3_BUCKET/app-release.apk"
    APP_FILE_NAME=$APK_FILE
    APP_TYPE="ANDROID_APP"
else
    echo "Unsupported platform: $environment"
    exit 1
fi

# Compile the TestNGXmlGenerator class
javac -d out -sourcepath src/main/java src/main/java/com/spe/SPConnect/utils/TestNGXmlGenerator.java

# Create the TestNG XML file
java -cp out com.spe.SPConnect.utils.TestNGXmlGenerator "$environment" "$TESTNG_XML_FILE" "CategoryScreen"

# Replace underscores with spaces
DEVICE_POOL_NAME_WITH_SPACES="${DEVICE_POOL_NAME//_/ }"

# Extract the last part (version) and remove it from the string
VERSION=$(echo "$DEVICE_POOL_NAME_WITH_SPACES" | awk '{print $NF}')
MODEL=$(echo "$DEVICE_POOL_NAME_WITH_SPACES" | sed "s/ $VERSION//")

echo "Model: $MODEL"
echo "OS Version: $VERSION"

# Read device pool rules template and replace placeholders
DEVICE_POOL_RULES=$(cat device_pool_rules_template.json | sed "s/{{PLATFORM}}/$PLATFORM_VALUE/g" | sed "s/{{OS_VERSION}}/$VERSION/g" | sed "s/{{MANUFACTURER}}/$MANUFACTURER_VALUE/g" | sed "s/{{MODEL}}/$MODEL/g")

ls

## Create a zip test package
echo "Creating zip test package..."
mvn clean package -DskipTests=true

ls

PROJECT_ARN=$(aws devicefarm list-projects --query "projects[?name=='$PROJECT_NAME'].arn" --output text)
echo "Project arn is : $PROJECT_ARN"

# Upload the package to Device Farm
echo "Uploading test package to Device Farm..."
TEST_PACKAGE_UPLOAD=$(aws devicefarm create-upload --project-arn "$PROJECT_ARN" --name "$DEPENDENCY_ZIP" --type "APPIUM_JAVA_TESTNG_TEST_PACKAGE")
TEST_PACKAGE_UPLOAD_ARN=$(echo $TEST_PACKAGE_UPLOAD | jq -r '.upload.arn')
TEST_PACKAGE_UPLOAD_URL=$(echo $TEST_PACKAGE_UPLOAD | jq -r '.upload.url')
echo "Test Package Upload arn is : $TEST_PACKAGE_UPLOAD_ARN"

curl -T "./target/$DEPENDENCY_ZIP" "$TEST_PACKAGE_UPLOAD_URL"

# Download APK/IPA from S3
echo "Downloading Zip from S3 and uploading to Device Farm..."
aws s3 cp $S3_BUCKET/$DEPENDENCY_ZIP .

# Download APK/IPA from S3
echo "Downloading APK/IPA from S3 and uploading to Device Farm..."
aws s3 cp $S3_BUCKET_File_Path .

# Upload the APK or IPA to Device Farm
echo "Uploading APK/IPA file to Device Farm..."
APP_UPLOAD=$(aws devicefarm create-upload --project-arn "$PROJECT_ARN" --name "$APP_FILE_NAME" --type "$APP_TYPE")
APP_UPLOAD_ARN=$(echo $APP_UPLOAD | jq -r '.upload.arn')
APP_UPLOAD_URL=$(echo $APP_UPLOAD | jq -r '.upload.url')

curl -T $APP_FILE_NAME $APP_UPLOAD_URL

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

# Check if the YAML file already exists and delete it if it does
EXISTING_YML_ARN=$(aws devicefarm list-uploads --arn "$PROJECT_ARN" --query "uploads[?name=='$YML_FILE'].arn" --output text)
if [ -n "$EXISTING_YML_ARN" ]; then
    echo "YAML file '$YML_FILE' already exists. Deleting existing file..."
    aws devicefarm delete-upload --arn "$EXISTING_YML_ARN"
fi

# Upload the YAML file to Device Farm
echo "Uploading YAML file to Device Farm..."
YML_UPLOAD=$(aws devicefarm create-upload --project-arn "$PROJECT_ARN" --name "$YML_FILE" --type "APPIUM_NODE_TEST_SPEC")
YML_UPLOAD_ARN=$(echo $YML_UPLOAD | jq -r '.upload.arn')
YML_UPLOAD_URL=$(echo $YML_UPLOAD | jq -r '.upload.url')

# Wait for the YAML upload to succeed
while true; do
    YML_UPLOAD_STATUS=$(aws devicefarm get-upload --arn $YML_UPLOAD_ARN | jq -r '.upload.status')
    echo "YAML Upload status is: $YML_UPLOAD_STATUS"
    if [[ "$YML_UPLOAD_STATUS" == "SUCCEEDED" ]]; then
        break
    elif [[ "$YML_UPLOAD_STATUS" == "FAILED" ]]; then
        echo "YAML upload failed"
        exit 1
    else
        echo "Waiting for YAML upload to complete..."
        sleep 10
    fi
done

# Fetch the ARN of the test spec
#echo "Fetching ARN of the test spec..."
#YML_UPLOAD_ARN=$(aws devicefarm list-uploads --arn "$PROJECT_ARN" --query "uploads[?name=='$TEST_SPEC_NAME'].arn" --output text)
echo "Test spec arn is: $YML_UPLOAD_ARN"

# Fetch the ARN of the device pool
echo "Fetching ARN of the device pool..."
# Check if the device pool exists
DEVICE_POOL_ARN=$(aws devicefarm list-device-pools --arn "$PROJECT_ARN" --query "devicePools[?name=='$DEVICE_POOL_NAME'].arn" --output text)

# Create the device pool if it does not exist
if [ -z "$DEVICE_POOL_ARN" ]; then
    echo "Device pool '$DEVICE_POOL_NAME' does not exist. Creating device pool..."
    DEVICE_POOL_ARN=$(aws devicefarm create-device-pool --project-arn "$PROJECT_ARN" --name "$DEVICE_POOL_NAME" --description "$DEVICE_POOL_DESCRIPTION" --rules "$DEVICE_POOL_RULES" --query "devicePool.arn" --output text)
    echo "Device pool created with ARN: $DEVICE_POOL_ARN"
else
    echo "Device pool '$DEVICE_POOL_NAME' already exists with ARN: $DEVICE_POOL_ARN"
fi

# Export the device pool ARN for use in other parts of the script
export DEVICE_POOL_ARN

echo "Device Pool arn is: $DEVICE_POOL_ARN"

export TZ=Asia/Kolkata

current_datetime=$(date +'%Y-%m-%d_%H:%M:%S')

# Schedule the run
echo "Scheduling the run..."
RUN=$(aws devicefarm schedule-run --project-arn "$PROJECT_ARN" --app-arn "$APP_UPLOAD_ARN" --device-pool-arn "$DEVICE_POOL_ARN" --name "TestRun_$current_datetime" --test testSpecArn="$YML_UPLOAD_ARN",type=APPIUM_JAVA_TESTNG,testPackageArn="$TEST_PACKAGE_UPLOAD_ARN")

echo "Run scheduled successfully!"

RUN_ARN=$(echo $RUN | jq -r '.run.arn')
echo "Run arn is: $RUN_ARN"

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
CUSTOMER_ARTIFACTS_URL=$(aws devicefarm list-artifacts --arn "$RUN_ARN" --type FILE --query "artifacts[?name=='Customer Artifacts'].url" --output text)
echo "Report URL is: $CUSTOMER_ARTIFACTS_URL"

# Download the test report
echo "Downloading the test report..."
curl -o customer-artifacts.zip $CUSTOMER_ARTIFACTS_URL

#Unzip the test report
echo "Unzip the test report..."
unzip customer-artifacts.zip -d test-report

#Fetch test case execution metadata
export passed_testcases=$(xmlstarlet sel -t -v "/testng-results/@passed" /app/test-report/Host_Machine_Files/*DEVICEFARM_LOG_DIR/test-output/testng-results.xml)
export failed_testcases=$(xmlstarlet sel -t -v "/testng-results/@failed" /app/test-report/Host_Machine_Files/*DEVICEFARM_LOG_DIR/test-output/testng-results.xml)
export skipped_testcases=$(xmlstarlet sel -t -v "/testng-results/@skipped" /app/test-report/Host_Machine_Files/*DEVICEFARM_LOG_DIR/test-output/testng-results.xml)
export tc_start_time=$(xmlstarlet sel -t -v "/testng-results/suite/@started-at" /app/test-report/Host_Machine_Files/*DEVICEFARM_LOG_DIR/test-output/testng-results.xml)
export tc_end_time=$(xmlstarlet sel -t -v "/testng-results/suite/@finished-at" /app/test-report/Host_Machine_Files/*DEVICEFARM_LOG_DIR/test-output/testng-results.xml)
export total_testcases=$((passed_testcases+failed_testcases+skipped_testcases))
export testcase_status=$( [ "$failed_testcases" -eq 0 ] && echo "success" || echo "failure" )

echo "Passed test case: $passed_testcases"
echo "Failed test case: $failed_testcases"
echo "Skipped test case: $skipped_testcases"
echo "Total Test case: $total_testcases"
echo "Test case start time: $tc_start_time"
echo "Test case end time: $tc_end_time"
echo "Test Case Status: $testcase_status"

# Upload the test report to S3
echo "Uploading the test report to S3..."
aws s3 cp --acl bucket-owner-full-control --recursive test-report/Host_Machine_Files/ $S3_BUCKET/test-report_$current_datetime && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
