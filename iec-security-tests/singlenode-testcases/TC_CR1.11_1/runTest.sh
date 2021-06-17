#!/bin/bash
# Security Test case
# TC_CR1.11_1: Unsuccessful login attempts - limit number
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.11_1: Unsuccessful login attempts - limit number"

PAM_FILE="/etc/pam.d/common-auth"
pam_tally="auth   required  pam_tally2.so  deny=3 even_deny_root unlock_time=60 \
root_unlock_time=60 account     required      pam_tally2.so"

preTest() {
    check_root
    check_pkgs_installed "libpam-modules" "libpam-modules-bin"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER2_NAME $USER2_PSWD

    # If pam_craclib already configured, comment that temporarily
    sed -i '/pam_tally2.so/ s/^/#/' $PAM_FILE

}

runTest() {
    wrong_pwd="TC_CR1_11_3"
    user1_successful_login="echo '$USER1_PSWD' | su - '$USER1_NAME' -c \"whoami\""
    user1_unsuccessful_login="echo '$wrong_pwd\n$wrong_pwd\n$wrong_pwd' | su - '$USER1_NAME' -c \"whoami\""

    # configure pam to lock user accounts after 3 failed login attempt
    sed -i "0,/^auth.*/s/^auth.*/${pam_tally}\n&/" "${PAM_FILE}"

    # Reset the attempts counter.
    pam_tally2 --user "${USER1_NAME}" --reset

    # check if account is login successful
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_successful_login")
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "account is Logged in '$USER1_NAME'"
    else
        error_msg "FAIL: Unable to login account '$USER1_NAME'"
    fi

    # attempt unsuccessful login attempts
    for i in {1..3}; do
        msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_unsuccessful_login | cat")
        if [ "$msg" != "$USER1_NAME" ];then
            info_msg "Attempted unsuccessful login '$USER1_NAME'"
        else
            error_msg "FAIL: unable to attempt unsuccessful login '$USER1_NAME'"
        fi
    done

    pam_tally2 --user "${USER1_NAME}"

    # check if account is locked due to unsuccessful login attempts
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_successful_login | cat")
    if [ "$msg" != "$USER1_NAME" ]; then
        info_msg "'$USER1_NAME' account is locked due to unsuccessful login attempts"
    else
        error_msg "FAIL: Account is not locked after unsuccessful login attempts"
    fi

    info_msg "PASS"
}

postTest() {
    # remove the configuration of lock user account for unsuccessful login attempts
    sed -i "0,/${pam_tally}/d" "${PAM_FILE}"

    # uncomment the configuration that was commented in preTest
     sed -i '/pam_tally2.so/ s/^#//' $PAM_FILE

    pam_tally2 --user "${USER1_NAME}" --reset

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