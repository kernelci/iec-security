#!/bin/bash
# Security Test case
# TC_CR1.11_2: Unsuccessful remote login attempts - limit number
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.11_2: Unsuccessful login attempts - limit number"

PAM_FILE="/etc/pam.d/common-auth"
pam_tally="auth   required  pam_tally2.so  deny=1 even_deny_root unlock_time=10 \
root_unlock_time=10 account     required      pam_tally2.so"

preTest() {
    check_root
    check_pkgs_installed "libpam-modules" "openssh-server" "openssh-client" "sshpass"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER2_NAME $USER2_PSWD

    # If pam_craclib already configured, comment that temporarily
    sed -i '/pam_tally2.so/ s/^/#/' $PAM_FILE

    # configure pam to lock user accounts for specified time 10sec
    sed -i "0,/^auth.*/s/^auth.*/${pam_tally}\n&/" "${PAM_FILE}"

    if ! grep -x -c "^UsePAM yes" /etc/ssh/sshd_config;then
		echo "UsePAM yes" >> /etc/ssh/sshd_config
        service sshd restart
	fi
}

runTest() {
    wrong_pwd="TC_CR1_11_2"
    user1_successful_login="sshpass -p $USER1_PSWD ssh -o StrictHostKeyChecking=no $USER1_NAME@127.0.0.1 \"whoami\""
    user1_unsuccessful_login="sshpass -p '$wrong_pwd' ssh -o StrictHostKeyChecking=no '$USER1_NAME'@127.0.0.1 \"whoami\""

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
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_unsuccessful_login | cat")
    if [ "$msg" != "$USER1_NAME" ];then
        info_msg "Attempted unsuccessful login '$USER1_NAME'"
    else
        error_msg "FAIL: unable to attempt unsuccessful login '$USER1_NAME'"
    fi

    pam_tally2 --user "${USER1_NAME}"

    # check if account is locked due to unsuccessful login attempts
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_successful_login | cat")
    if [ "$msg" != "$USER1_NAME" ]; then
        info_msg "'$USER1_NAME' account is locked due to unsuccessful login attempts"
    else
        error_msg "FAIL: Account is not locked after unsuccessful login attempts"
    fi

    info_msg "Sleep until unlock time complete 10s"
    sleep 10s

    # check if account is unlocked
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "$user1_successful_login | cat")
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "'$USER1_NAME' account is unlocked"
    else
        error_msg "FAIL: Account is not unlocked"
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