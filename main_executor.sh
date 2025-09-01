#!/bin/bash
set -e  # Exit the script if any command fails

export TZ=UTC

aws s3 cp --acl bucket-owner-full-control --recursive s3://tf-rf-scripts-spe-qaqc-bucket/SPTNetwork_RF/aut-rf-sptnetwork/ .

report_folder_to_cleanup="report"
# Clean up and create the report folder
if [ -d "$report_folder_to_cleanup" ]; then
    echo "Cleaning up folder $report_folder_to_cleanup"
    rm -rf "$report_folder_to_cleanup"
fi
mkdir "$report_folder_to_cleanup"

ls
pwd
#cd cloneRepos && echo "Changed to cloneRepos directory"
#ls

trap - ERR
#pabot_cmd="pabot --processes 10 --outputdir reports --output output.xml -v Jeopardy_UserID:$SPT_Network_Gettv__AdminUser_Username -v Jeopardy_pswd:$SPT_Network_Gettv__AdminUser_psd -v Format_Reviewer_Username:$Format_Reviewer_Username -v Format_Reviewer_Password:$Format_Reviewer_Password -v Media_Editor_Username:$Media_Editor_Username -v Media_Editor_Password:$Media_Editor_Password -v Media_Reviewer_Username:$Media_Reviewer_Username -v Media_Reviewer_Password:$Media_Reviewer_Password -v Preview_editor_usename:$Preview_editor_usename -v preview_reviewer_password:$preview_reviewer_password -v preview_reviewer_username:$preview_reviewer_username -v preview_reviewer_username:$preview_reviewer_username -v Preview_editor_password:$Preview_editor_password -v Millionaire_PSWD:$Millionaire_PSWD -v ENV:$environment -v BROWSER:$browser"
pabot_cmd="pabot --processes 5 --outputdir reports --output output.xml -v user_id:$SPT_Network_Gettv__ReviewerUser_Username -v pswd:'$SPT_Network_Gettv__ReviewerUser_psd' -v Jeopardy_UserID:$SPT_Network_Gettv__AdminUser_Username -v Jeopardy_pswd:$SPT_Network_Gettv__AdminUser_psd -v Kids_Editor_username:$SPT_Network_Kids_ReviewerUser_ID -v Kids_Editor_pswd:'$SPT_Network_Kids_ReviewerUser_psd' -v Editor_username:$SPT_Network_SetSounds_AdminUser_ID -v Editor_pswd:'$SPT_Network_SetSounds_AdminUser_pswd' -v Reviewer_username:$SPT_Network_SetSounds_ReviewerUser_ID -v Reviewer_pswd:'$SPT_Network_SetSounds_ReviewerUser_psd' -v ENV:$environment -v BROWSER:$browser"
echo "$pabot_cmd"
eval $pabot_cmd TestSuits/SPT_Network/Jeopardy.robot


trap 'catch $? ${LINENO}' ERR

#Fetch test case execution metadata
export passed_testcases=$(xmlstarlet sel -t -v "/robot/statistics/total/stat[1]/@pass" /automation_Robot_app/reports/output.xml)
export failed_testcases=$(xmlstarlet sel -t -v "/robot/statistics/total/stat[1]/@fail" /automation_Robot_app/reports/output.xml)
export skipped_testcases=$(xmlstarlet sel -t -v "/robot/statistics/total/stat[1]/@skip" /automation_Robot_app/reports/output.xml)
export tc_start_time=$(xmlstarlet sel -t -v "/robot/suite/status/@starttime" /automation_Robot_app/reports/output.xml)
export tc_end_time=$(xmlstarlet sel -t -v "/robot/suite/status/@endtime" /automation_Robot_app/reports/output.xml)
export total_testcases=$((passed_testcases+failed_testcases+skipped_testcases))
export testcase_status=$( [ "$failed_testcases" -eq 0 ] && echo "success" || echo "failure" )

echo "Passed test case: $passed_testcases"
echo "Failed test case: $failed_testcases"
echo "Skipped test case: $skipped_testcases"
echo "Total Test case: $total_testcases"
echo "Test case start time: $tc_start_time"
echo "Test case end time: $tc_end_time"
echo "Test Case Status: $testcase_status"

aws s3 cp --acl bucket-owner-full-control  --recursive /automation_Robot_app/reports s3://tf-rf-scripts-spe-qaqc-bucket/SPTNetwork_RF_Report/ && echo "Copied report to s3 bucket" || echo "Copying report to s3 bucket failed"
