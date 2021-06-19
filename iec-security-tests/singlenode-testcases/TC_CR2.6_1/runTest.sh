#!/bin/bash
# Security Test case
# TC_CR2.6_1: Remote session termination
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.6_1: Remote session termination"

SSHD_CONFIG="/etc/ssh/sshd_config"
preTest() {
    check_root
    check_pkgs_installed "openssh-server" "openssh-client" "sshpass"

    # Backup ssh configuration file
    cp $SSHD_CONFIG sshd_config.bkp

    # Configure ssh for remote session termination
    sed -i "/ClientAliveInterval/c ClientAliveInterval 5"  "${SSHD_CONFIG}"
	sed -i "/ClientAliveCountMax/c ClientAliveCountMax 1" "${SSHD_CONFIG}"
    service sshd restart

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # Check User can access the account
    msg=$(sshpass -p $USER1_PSWD ssh -o StrictHostKeyChecking=no $USER1_NAME@127.0.0.1 "whoami" | cat)
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "User can access the remote session"
    else
        error_msg "FAIL: User can not access the remote session"
    fi

    # Check remote session termination
    sshpass -p $USER1_PSWD ssh -o StrictHostKeyChecking=no $USER1_NAME@127.0.0.1 "sleep 6s" > output.log 2>&1 || echo
    if grep -q "closed by remote host" output.log; then
        info_msg "Remote session is closed by host, after timeout"
    else
        error_msg "Remote session is not closed by host after timeout"
    fi

    info_msg "PASS"
}

postTest() {

    [ -f output.log ] && rm -f output.log

    # Restore previous configuration
    [ -f sshd_config.bkp ] && mv sshd_config.bkp $SSHD_CONFIG

    # Delete the user that was created for the test
    del_user $USER1_NAME

    service sshd restart
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
