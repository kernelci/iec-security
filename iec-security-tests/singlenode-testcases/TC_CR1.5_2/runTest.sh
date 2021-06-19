#!/bin/bash
# Security Test case
# TC_CR1.5_2: Validate periodic authenticator change
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.5_2: Validate periodic authenticator change"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {
    # Set user password expire time
    next_day=$(date "+%Y-%m-%d" --date="next day")
    if chage -E "$next_day" -I 2 -m 0 -M 7 -W 5 $USER1_NAME; then
        info_msg "set user account expire time to next day"
    else
        error_msg "FAIL: Cannot set password expire time for the user '$USER1_NAME'"
    fi

    # Verify user password expire information change
    min_no_days=$(chage -l $USER1_NAME | awk -F: '/^Minimum number/ {gsub(/ /,"");print $2}')
    max_no_days=$(chage -l $USER1_NAME | awk -F: '/^Maximum number/ {gsub(/ /,"");print $2}')
    war_no_days=$(chage -l $USER1_NAME | awk -F: '/^Number of days of warning/ {gsub(/ /,"");print $2}')
    info_msg "User password expire information:"
    info_msg "Minimum number of days between password change: $min_no_days"
    info_msg "Maximum number of days between password change: $max_no_days"
    info_msg "Number of days of warning before password expires: $war_no_days"
    if [ $min_no_days -eq 0 ] && [ $max_no_days -eq 7 ] && [ $war_no_days -eq 5 ]; then
        info_msg "Verified user password expiry information change"
    else
        error_msg "FAIL: Password expiry information is not same as set earlier"
    fi

    # Set user password expire it to now
    if chage -d 0 $USER1_NAME; then
        info_msg "Set user account expire it to now"
    else
        error_msg "FAIL: Cannot set password expire time for the user '$USER1_NAME'"
    fi   

    # Verify user password is expired
    expected_msg="You are required to change your password immediately"
    login_msg=$(echo "$USER1_PSWD" | su - $USER1_NAME -c "whoami" 2>&1 | cat )
    if [ "$login_msg" != "$USER1_NAME" ] && [ -z "${login_msg##*$expected_msg*}" ]; then
        info_msg "User password is expired"
    else
        error_msg "FAIL: User password is not expired"
    fi

    # Change the user password
    new_paswd="fgsT@623tD"
    if echo "$USER1_NAME:$new_paswd" | chpasswd ;then
        info_msg "User password is changed"
    else
        error_msg "FAIL: Cannot change user password"
    fi

    # Validate user account login
    login_name=$(echo "$new_paswd" | su - $USER1_NAME -c "whoami")
    if [ "$login_name" = "$USER1_NAME" ];then
        info_msg "Verified User login with new password"
    else
        error_msg "FAIL: Cannot login to user with new password"
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
