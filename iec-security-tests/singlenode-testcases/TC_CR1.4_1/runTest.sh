#!/bin/bash
# Security Test case
# TC_CR1.4_1: Identifier management
#
# Validate Deny creating human user accounts  with user name and 
# uid which already exists

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.4_1: Identifier management"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER3_NAME $USER3_PSWD
}

runTest() {
    # Get UID of user1
    user1_uid=$(id -u "${USER1_NAME}")
    if [ "$user1_uid" = "" ]; then
        error_msg "FAIL: Can not get unique id of the user"
    fi

    # Check uniqueness of users name and UID
    info_msg "Check uniqueness of user by creating user2 with same UID of user1 or name"
    if ! useradd -u "${user1_uid}"  "${USER2_NAME}"  && \
        ! usermod -l "${USER1_NAME}" "${USER3_NAME}";then
        info_msg "PASS"
    else
        error_msg "FAIL"
    fi
}

postTest() {
    # Remove the users created for the test case
	user="$USER1_NAME $USER2_NAME $USER3_NAME"
	for u in $user;do del_user "${u}"; done
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