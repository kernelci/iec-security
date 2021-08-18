#!/bin/bash
# Security Test case
# TC_CR2.1_1: Authorization enforcement
#

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.1_1: Authorization enforcement"

preTest() {
    check_root
    check_pkgs_installed "sudo"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    if ! echo "$USER1_PSWD" | su - $USER1_NAME -c "sudo -vknS"; then
        info_msg "User '$USER1_NAME' has no supervisor prvilieges"
    else
        error_msg "FAIL: Have already supervisor prvilieges"
    fi

    # provide supervisor prvilieges to the user
	if echo "$USER1_NAME ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo ; then
        info_msg "Provided supervisor prvilieges to the user '$USER1_NAME'"
    else
        error_msg "FAIL: cannot give supervisor prvilieges to the user '$USER1_NAME'"
    fi

    # access the file to check whether supervisor prvilieges gives
    if echo "$USER1_PSWD" | su - $USER1_NAME -c "echo '$USER1_PSWD' | sudo -vkS"; then
        info_msg "User $USER1_NAME has supervisor prvilieges"
    else
        error_msg "FAIL: Doesn't have supervisor prvilieges"
    fi

    info_msg "PASS"
}

postTest() {
    sed -i '/^'$USER1_NAME'/d' /etc/sudoers
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
