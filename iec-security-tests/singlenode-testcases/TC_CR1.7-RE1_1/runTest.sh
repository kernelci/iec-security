#!/bin/bash
# Security Test case
# TC_CR1.7-RE1_1: Validate Setting password life restrictions
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.7-RE1_1: Validate Setting password life restrictions"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {
    # Set user password expire time
    if chage -m 0 -M 7 -W 5 $USER1_NAME; then
        info_msg "Set password life restrictions"
    else
        error_msg "FAIL: Cannot set password life restriction to the user '$USER1_NAME'"
    fi

    # Verify user password life restrictions change
    min_no_days=$(chage -l $USER1_NAME | awk -F: '/^Minimum number/ {gsub(/ /,"");print $2}')
    max_no_days=$(chage -l $USER1_NAME | awk -F: '/^Maximum number/ {gsub(/ /,"");print $2}')
    war_no_days=$(chage -l $USER1_NAME | awk -F: '/^Number of days of warning/ {gsub(/ /,"");print $2}')
    if [ $min_no_days -eq 0 ] && [ $max_no_days -eq 7 ] && [ $war_no_days -eq 5 ]; then
        info_msg "Verified user password life restriction change"
    else
        error_msg "FAIL: Password life restriction is not same as set earlier"
    fi

    info_msg "PASS"
}

postTest() {
    # delete the user created in the test
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