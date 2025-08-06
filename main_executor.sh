#!/bin/bash
set -e  # Exit the script if any command fails

export TZ=UTC

aws s3 cp --acl bucket-owner-full-control --recursive s3://tf-rf-scripts-spe-qaqc-bucket/SOAR_Script/aut-playwright-soar/ .

ls

run_command() {
    echo "Running: $1"
    eval $1
    if [ $? -ne 0 ]; then
        echo "Error: Command '$1' failed"
       catch $exit_code ${LINENO}
    fi
}

echo "change directory to playwright repo"
#cd /playwright/cloneRepos && echo "Successfully changed the directory to cloneRepos directory" || echo "Unable to change the directory to cloneRepos directory"

# Ping domain check
echo "Checking connectivity to CloudFront domain..."
ping_domain="d3gcli72yxqn2z.cloudfront.net"
ping -c 4 $ping_domain && echo "Successfully pinged $ping_domain" || echo "Failed to ping $ping_domain"

# Ensure the node_modules directory exists and set permissions if it does
if [ -d "node_modules" ]; then
    chmod -R a+x node_modules
    echo "Permissions set for node_modules."
else
    echo "Warning: node_modules directory not found. Skipping chmod."
fi
echo "list the files"
ls -ltr

echo "Current Playwright version is: $(npx playwright --version)"
echo "Chrome Browser version is: $($(find /ms-playwright -type f -name "chrome") --version)"
# Ensure the environment variable is set
export PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
echo "PLAYWRIGHT_BROWSERS_PATH is set to: $PLAYWRIGHT_BROWSERS_PATH"
run_command "npm cache clean --force"
echo Installing dependencies...

#AWS docker image uses 1.45 version. Keep playwright and playwright test to use less than 1.49 
run_command "npm install playwright@1.51.0"                                          
run_command "npm install -D @playwright/test@1.51.0 -y"
run_command "npm install mammoth"
npm list
run_command "npx playwright install || true"
run_command "npm install dotenv --save || true"
run_command "npm install --save-dev cross-env || true"
run_command "npm install xlsx-populate || true"
run_command "npm install exceljs || true"
run_command "npm install csv-parse || true"    
run_command "npm install moment --save"

echo "Running popup test"
run_command "npm run awsTestpopup || true"

echo "Playwright version is:"
npx playwright --version

echo "list the files"
ls -ltr
aws s3 cp --acl bucket-owner-full-control --recursive /playwright/test-results s3://tf-rf-scripts-spe-qaqc-bucket/SOAR_Report/ && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
aws s3 cp --acl bucket-owner-full-control --recursive /playwright/playwright-report s3://tf-rf-scripts-spe-qaqc-bucket/SOAR_Report/ && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
aws s3 cp --acl bucket-owner-full-control  /playwright/results.json s3://tf-rf-scripts-spe-qaqc-bucket/SOAR_Report/ && echo "Copied report to s3 bucket"
#aws s3 cp --acl bucket-owner-full-control  /playwright/helper/auth/userAuth.json s3://$REPORT_BUCKET/$repo/$branch/$task_start_time/$ecs_task_id/ && echo "Copied report to s3 bucket"
