#!/bin/bash
# Security Test case
# TC_CR3.9_1: Protection of audit information
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR3.9_1: Protection of audit information"

AUDIT_LOG_FILE="/var/log/audit/audit.log"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # Check if the user has permission to delete the audit log files
    if ! echo $USER1_PSWD | su - $USER1_NAME -c "rm -rf $AUDIT_LOG_FILE"; then
        info_msg "Cannot delete the audit log file from the user"
    else
        error_msg "FAIL: Able to delete the audit log file from the user"
    fi

    info_msg "PASS"
}

postTest() {
    # Delete the user that was created for the test
    del_user $USER1_NAME
}

# Main
cmd="$1"
case "$1" in
    "init")
        echo ""
        echo "preTest: $TEST_CASE_NAME"
        preTest
        ;;
    "run")
        echo ""
        echo "runTest: $TEST_CASE_NAME"
        runTest
        ;;
    "clean")
        echo ""
        echo "postTest: $TEST_CASE_NAME"
        postTest
        ;;
esac
