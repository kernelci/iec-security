#!/bin/bash
# Security Test case
# TC_CR4.1_1: Information confidentiality - at rest
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR4.1_1: Information confidentiality - at rest"

preTest() {
    check_root
    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # A good Example of data confidentiality at rest in linux is /etc/shadow file
    # where the password hash values are copied instead their plain password text
    # Verify whether shadow file contains the user password plain text
    user_pwd=$(awk -F: -v user=$USER1_NAME '{ if($1 == user) {print $2}}' /etc/shadow)
    if [ -z "$user_pwd" ];then
        error_msg "FAIL: User account not found in shadow file"
    elif [ "$user_pwd" = "$USER1_PSWD" ];then
        error_msg "FAIL: User account password can be read"
    else
        info_msg "User account password is encrypted"
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