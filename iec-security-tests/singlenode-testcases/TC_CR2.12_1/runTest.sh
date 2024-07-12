#!/bin/bash
# Security Test case
# TC_CR2.12_1: Non-repudiation
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.12_1: Non-repudiation"

AUDIT_CONF="/etc/audit/auditd.conf"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file =.*/max_log_file = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file_action =.*/max_log_file_action = rotate/' $AUDIT_CONF
    sed -i 's/^space_left =.*/space_left = 20/' $AUDIT_CONF
    sed -i 's/^admin_space_left =.*/admin_space_left = 10/' $AUDIT_CONF

    # start audit service
    auditctl -e 1
    service auditd restart
}

runTest() {

    start_time="$(date +"%m/%d/%y %T")"

    # Delete the user
    create_test_user $USER1_NAME $USER1_PSWD

    # Verify if the audit event is generated
    acc_change=$(ausearch -i --start $start_time -m DEL_USER | sed -n '/^----/!p' | wc -l)
    if [ $acc_change -eq 0 ]; then
        error_msg "FAIL: Can not record the user deleting event"
    else
        info_msg "Recorded deletion event Non-repudiation"
    fi

    info_msg "PASS"  
}

postTest() {
    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

    # Delete the user that was created for the test
    del_user $USER1_NAME

    # stop audit service
    auditctl -e 0
    service auditd stop
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