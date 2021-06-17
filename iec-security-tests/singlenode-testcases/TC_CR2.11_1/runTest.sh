#!/bin/bash
# Security Test case
# TC_CR2.11_1: Validate creation of timestamps 
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.11_1: Validate creation of timestamps "

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # start audit service
    service auditd start
}

runTest() {
    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    audit_record=$(ausearch -m ADD_USER | tail -2)
    time_stamp=$(echo $audit_record | sed -n 's/.*time->\(.*\).*type=.*/\1/p')

    info_msg "time stamp: $time_stamp"
    if [ -z "$time_stamp" ]; then
        error_msg "FAIL: some of the data fields are not recorded"
    else
        info_msg "Time stamp: $time_stamp"
    fi

    info_msg "PASS"
}

postTest() {
    # Delete the user that was created for the test
    del_user $USER1_NAME

    # stop audit service
    service auditd stop
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