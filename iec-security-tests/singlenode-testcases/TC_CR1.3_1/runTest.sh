#!/bin/sh
# TC_CR1.3_1 : Validating Creating human user accounts
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.3_1 : Validating Creating human user accounts"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # delete the users if already present
    del_user $USER1_NAME
}

runTest() {
    # Add user
    if  add_user $USER1_NAME $USER1_PSWD; then
        # Login and get the username to verify user creation
        if echo "${USER1_PSWD}" | su - "${USER1_NAME}" -c 'whoami';then
            info_msg "PASS"
        else
            error_msg "FAIL: Cannot login to created user account"
        fi
    else
        error_msg "FAIL: Cannot create user account"
    fi
}

postTest() {
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