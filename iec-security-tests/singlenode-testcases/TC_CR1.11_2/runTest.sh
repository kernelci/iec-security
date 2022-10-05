#!/bin/bash
# Security Test case
# TC_CR1.11_2: Unsuccessful login attempts - limit number
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.11_2: Unsuccessful remote login attempts - limit number"

# pam_tally2 is deprecated from pam 1.4.0-7
pam_tally2=( /lib/*-linux-gnu*/security/pam_tally2.so )
if [ -f "${pam_tally2[0]}" ]; then
    PAM_TALLY_MODULE="pam_tally2.so"
    PAM_TALLY_CONFIG="auth   required $PAM_TALLY_MODULE deny=1 unlock_time=10 \
                        \naccount required $PAM_TALLY_MODULE"
    PAM_TALLY_BIN="pam_tally2"
else
    pam_faillock=( /lib/*-linux-gnu*/security/pam_faillock.so )
    if [ -f "${pam_faillock[0]}" ]; then
        PAM_TALLY_MODULE="pam_faillock.so"
        PAM_TALLY_CONFIG="auth required $PAM_TALLY_MODULE preauth silent deny=1 unlock_time=10 \
                        \nauth required $PAM_TALLY_MODULE authfail deny=1 unlock_time=10"
        PAM_TALLY_BIN="faillock"
    else
        echo "No suitable pam module found to lock failed login attempts"
    fi
fi

PAM_FILE="/etc/pam.d/common-auth"

preTest() {
    check_root
    check_pkgs_installed "libpam-modules" "openssh-server" "openssh-client" "sshpass"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
    create_test_user $USER2_NAME $USER2_PSWD

    # Take backup of pam configuration
    cp $PAM_FILE pam-common-auth.bkp

    # If pam_craclib already configured, comment that temporarily
    sed -i "/${PAM_TALLY_MODULE}/ s/^/#/" "${PAM_FILE}"

    # configure pam to lock user accounts for specified time
    sed -i "0,/^auth.*/s/^auth.*/${PAM_TALLY_CONFIG}\n&/" "${PAM_FILE}"

    if ! grep -x -c "^UsePAM yes" /etc/ssh/sshd_config;then
        echo "UsePAM yes" >> /etc/ssh/sshd_config
    fi
    service sshd restart
}

runTest() {
    wrong_pwd="wrongpassword"
    user1_successful_login="sshpass -p $USER1_PSWD ssh -o StrictHostKeyChecking=no $USER1_NAME@127.0.0.1 \"whoami\""
    user1_unsuccessful_login="sshpass -p '$wrong_pwd' ssh -o StrictHostKeyChecking=no '$USER1_NAME'@127.0.0.1 \"whoami\""

    # Reset the attempts counter.
    $PAM_TALLY_BIN --user "${USER1_NAME}" --reset

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

    $PAM_TALLY_BIN --user "${USER1_NAME}"

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
    # Restore the previous configuration
    mv pam-common-auth.bkp $PAM_FILE

    $PAM_TALLY_BIN --user "${USER1_NAME}" --reset

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
