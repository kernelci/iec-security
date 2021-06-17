#!/bin/bash
# TC_CR1.3_3 : validate Disable and Enable human user  accounts
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.3_3 : Validate Disable and Enable human user accounts"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users required for the test
    create_test_user $USER1_NAME $USER1_PSWD    
}

runTest() {
    # Disable user account
    if usermod --expiredate 1 $USER1_NAME; then
        # Verify disable user account
        if ! echo "${USER1_PSWD}" | su - "${USER1_NAME}" -c "whoami"; then
            info_msg "PASS: User account '$USER1_NAME' Disabled"
        else
            error_msg "FAIL: Can login user account after disabling it"
        fi
    else
        error_msg "FAIL: Cannot disable the user account"
    fi

    # Enable user account
    if usermod --expiredate "" $USER1_NAME; then
        # Verify disable user account
        if echo "${USER1_PSWD}" | su - "${USER1_NAME}" -c "whoami"; then
            info_msg "PASS: User account '$USER1_NAME' Enabled"
        else
            error_msg "FAIL: Cannot login user account after enabling it"
        fi
    else
        error_msg "FAIL: Cannot enable the user account"
    fi
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