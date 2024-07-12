#!/bin/bash
# Security Test case
# TC_CR2.9_1: Audit storage capacity - allocation
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.9_1: Audit storage capacity - allocation"

AUDIT_CONF="/etc/audit/auditd.conf"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 5/' $AUDIT_CONF
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

    # Create the test user for generating audit event
    create_test_user $USER1_NAME $USER1_PSWD

    # Verify if the audit event is generated
    acc_change=$(ausearch -i --start $start_time -m ADD_USER | sed -n '/^----/!p' | wc -l)
    if [ $acc_change -eq 0 ]; then
        error_msg "FAIL: Can not record the user addition event"
    fi

    info_msg "PASS"  
}

postTest() {
    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

    # stop audit service
    auditctl -e 0
    service auditd stop

    # Delete the user
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
