#!/bin/bash
# TC_CR1.7_1: Validate Strength of password-based authentication
#
# This script verifies whether the system uses strong password for the user
# accounts.
# strong password should have minimum 8 characters, 1 lower case, 1 upper case
#  1 digit and 1 symbol.

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.7_1: Validate Strength of password-based authentication"

PAM_FILE="/etc/pam.d/common-password"

if [ -e /lib/*/security/pam_passwdqc.so ]; then
        bad_passwd_msg="Weak password"
        package="libpam-passwdqc"
else
        bad_passwd_msg="BAD PASSWORD"
        package="libpam-cracklib"
fi

preTest() {
    check_root
    check_pkgs_installed "$package" "libpam-runtime" "passwd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # Verify if system accept the weak password with one character class
    weak_pwd="testpassword"
    cmd_msg=$(echo "$USER1_NAME:$weak_pwd" | sudo chpasswd 2>&1 | cat)
    if echo $cmd_msg | grep -q "$bad_passwd_msg"; then
        info_msg "Password $weak_pwd is not accepted"
    else
        error_msg "FAIL: Accepting weak password $weak_pwd"
    fi

    # Verify if system accept the weak password with two character classes
    weak_pwd="testpasswd123"
    cmd_msg=$(echo "$USER1_NAME:$weak_pwd" | sudo chpasswd 2>&1 | cat)
    if echo $cmd_msg | grep -q "$bad_passwd_msg"; then
        info_msg "Password $weak_pwd is not accepted"
    else
        error_msg "FAIL: Accepting weak password $weak_pwd"
    fi

    # Verify if system accept the weak password with three character classes
    weak_pwd="testpasswd@123"
    cmd_msg=$(echo "$USER1_NAME:$weak_pwd" | sudo chpasswd 2>&1 | cat)
    if echo $cmd_msg | grep -q "$bad_passwd_msg"; then
        info_msg "Password $weak_pwd is not accepted"
    else
        error_msg "FAIL: Accepting weak password $weak_pwd"
    fi

    # Verify if system accept the weak password with four character classes
    # and password length < 8
    weak_pwd="TEst@12"
    cmd_msg=$(echo "$USER1_NAME:$weak_pwd" | sudo chpasswd 2>&1 | cat)
    if echo $cmd_msg | grep -q "$bad_passwd_msg"; then
        info_msg "Password $weak_pwd is not accepted"
    else
        error_msg "FAIL: Accepting weak password $weak_pwd"
    fi

    # Verify if system accept the strong password with four character classes
    # and password length = 8
    strong_pwd="HEllo@4567"
    echo "$USER1_NAME:$strong_pwd" | sudo chpasswd 2>&1
    if [ $? = "0" ];then
        info_msg "Password is changed with strong password"
    else
        error_msg "FAIL: Cannot change password"
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
