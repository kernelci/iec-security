#!/bin/bash
# Security Test case
# TC_CR1.1_2: Validate Human user identification and authentication from remote system
#
set -e

. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="Validate Human user identification and authentication from remote system"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login" "openssh-server" "openssh-client" "sshpass"

    # Create users required for the test
    create_test_user $USER1_NAME $USER1_PSWD 
}

runTest() {
    IP_ADDR=$(get_Host_IP_addr)

    # Login and verify the username
    user_name=$(sshpass -p "${USER1_PSWD}" ssh -o StrictHostKeyChecking=no ${USER1_NAME}@${IP_ADDR} "whoami")
    if [ "$user_name" = "$USER1_NAME" ];then
	    info_msg "PASS"
    else
	    error_msg "FAIL: Cannot authenticate local user account"
    fi
}

postTest() {
    # Delete the users created for the test
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