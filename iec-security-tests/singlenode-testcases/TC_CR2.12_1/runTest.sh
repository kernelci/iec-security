#!/bin/bash
# Security Test case
# TC_CR2.12_1: Non-repudiation
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.12_1: Non-repudiation"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # start audit service
    service auditd start
}

runTest() {

    start_time="$(date +"%m/%d/%y %T")"

    # Delete the user
    create_test_user $USER1_NAME $USER1_PSWD

    # Verify if the audit event is generated
    acc_change=$(ausearch -i --start $start_time -m DEL_USER | sed -n '/^----/!p' | wc -l)
    if [ $acc_change -eq 0 ]; then
        error_msg "FAIL: Can not record the user deleting event"
    else
        info_msg "Recorded deletion event Non-repudiation"
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