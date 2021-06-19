#!/bin/bash
# Security Test case
# TC_CR2.7_1: Concurrent session control
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.7_1: Concurrent session termination"

LIMITS_CONFIG="/etc/security/limits.conf"
CONCURRENT_SESSIONS_ALLOWED=2

preTest() {
    check_root
    check_pkgs_installed "libpam-modules" "openssh-server" "openssh-client" "sshpass"

    # Backup limits configuration file
    cp $LIMITS_CONFIG limits.conf.bkp

    # Configure pam for conurrent session control
    echo "@${USER1_NAME} hard maxlogins $CONCURRENT_SESSIONS_ALLOWED" >> ${LIMITS_CONFIG}

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

    # Establish concurrent sessions
    for i in $(seq 1 $CONCURRENT_SESSIONS_ALLOWED);do
        sshpass -p ${USER1_PSWD} ssh -tt -o StrictHostKeyChecking=no ${USER1_NAME}@127.0.0.1 'whoami && sleep 5s' > output$i.txt &
        sleep 1s
        ! grep -c "${USER1_NAME}" output$i.txt && error_msg "Concurrent connection failed"
        info_msg "Connected to remote session $i"
    done

    # Verify if the concurrent session for more than a limit is Success or not
    sshpass -p ${USER1_PSWD} ssh -tt ${USER1_NAME}@127.0.0.1 'sleep 2s' > output.txt &
    sleep 1s
    ! grep -c "Too many logins" output.txt && error_msg "Fail: Accepting concurrent sessions even after reaaching limit"

    info_msg "PASS"
}

postTest() {

    # Restore previous configuration
    [ -f limits.conf.bkp ] && mv limits.conf.bkp $LIMITS_CONFIG

    rm -rf output*

    # Delete the user that was created for the test
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