#!/bin/bash
# Security Test case
# TC_CR1.5_3: Validate protect of authenticators when stored.
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.5_3: Validate protect of authenticators when stored."

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER2_NAME $USER2_PSWD
}

runTest() {

    # Verify restrictions of /etc/shadow
    if ! echo "$USER1_PSWD" | su - $USER1_NAME -c "sed -i 's/^$USER2_NAME:/replace/g' /etc/shadow"; then
        info_msg "Accessing '/etc/shadow' is restricted"
    else
        error_msg "FAIL: Accessing '/etc/shadow' is not restricted"
    fi
    
    # Verify changing the password from unprivilaged user
    if ! echo "$USER1_PSWD" | su - $USER1_NAME -c "echo 'newpwd' | passwd $USER2_NAME"; then
        info_msg "Unable to Change password from unprivilaged user"
    else
        error_msg "FAIL: able to change password from unprivilaged user"
    fi

    info_msg "PASS"
}

postTest() {
    # delete the users created in the test
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