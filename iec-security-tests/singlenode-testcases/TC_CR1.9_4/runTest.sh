#!/bin/bash
# TC_CR1.9_4: Strength of public key-based authentication
# - establish user control of private key
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.9_4: Strength of public key-based authentication \
- establish user control of private key"

preTest() {
    check_root
    check_pkgs_installed "openssh-server"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER2_NAME $USER2_PSWD
}

runTest() {

    # Create ssh key pair for user1
    if echo "$USER1_PSWD" | su - $USER1_NAME -c \
                            "ssh-keygen -q -t rsa -P '' -f ~/.ssh/id_rsa <<< y"; then
        info_msg "Create ssh key pair for $USER1_NAME"
    else
        error_msg "FAIL: Unable to create ssh key pair for $USER1_NAME"
    fi

    # Create ssh key pair for user2
    if echo "$USER2_PSWD" | su - $USER2_NAME -c \
                            "ssh-keygen -q -t rsa -P '' -f ~/.ssh/id_rsa <<< y"; then
        info_msg "Create ssh key pair for $USER2_NAME"
    else
        error_msg "FAIL: Unable to create ssh key pair for $USER2_NAME"
    fi                            

    ls -al /home/$USER1_NAME/.ssh/id_rsa | \
        awk 'id_rsa' | \
        awk -v user=$USER1_NAME '$1=="-rw-------" && $3 == user && $4 == user'

    # Verify if user1 can access other user private key
    if ! echo "$USER2_PSWD" | su - $USER2_NAME -c \
                            "ls -al /home/$USER1_NAME/.ssh/id_rsa";then
        info_msg "Cannot access user private key"
    else
        error_msg "FAIL: user private key is accessible from other user"
    fi

    info_msg "PASS"
}

postTest() {
    # delete the user created in the test
    del_user $USER1_NAME
    del_user $USER2_NAME
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