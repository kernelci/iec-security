#!/bin/bash
# Security Test case
# TC_CR2.10_1: Response to audit processing failures
# - maintain essential functions
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.10_1: Response to audit processing failures \
- maintain essential functions"

AUDIT_CONF="/etc/audit/auditd.conf"
SYSLOG="/var/log/syslog"

preTest() {
    check_root
    check_pkgs_installed "syslog-ng-core" "auditd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file =.*/max_log_file = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file_action =.*/max_log_file_action = syslog/' $AUDIT_CONF
    sed -i 's/^space_left =.*/space_left = 20/' $AUDIT_CONF
    sed -i 's/^space_left_action =.*/space_left_action = syslog/' $AUDIT_CONF
    sed -i 's/^admin_space_left =.*/admin_space_left = 10/' $AUDIT_CONF
    sed -i 's/^admin_space_left_action =.*/admin_space_left_action = syslog/' $AUDIT_CONF

    # start audit service
    auditctl -e 1
    service auditd restart
}

runTest() {

    info_msg "Add Audit rules that will record diffrent events"
    # add audit rules to fill the audit storage
    auditctl -D
    auditctl -w /etc/passwd -p r -k control-system-event
    auditctl -a always,exit -S all -k file_access

    info_msg "Execute command to trigger the audit events"
    log_msg="start-test-$(date +%s)"
    logger $log_msg
    # trigger audit events to increase the audit log size greater than max_log_file size
    while true; do
        cat /etc/passwd > /dev/null
        audit_size=$(du -b /var/log/audit/audit.log | awk '{print $1}')
        if [ $audit_size -gt 1310720 ];then
            break
        fi
    done
    cat /etc/passwd > /dev/null
    echo "audit_size: $audit_size"

    sleep 1s
    audit_failure_msg="Audit daemon log file is larger than max size"
    log_msg_cnt=$(sed -n "/$log_msg/,/$audit_failure_msg/p" $SYSLOG | wc -l)
    if [ $log_msg_cnt -gt 1 ]; then
        info_msg "Warning message sent when Audit storage capacity is exceeded"
    else
        error_msg "FAIL: Not recieved warning message of Audit storage capacity is exceeded"
    fi

    info_msg "Check basic commands after exceed the audit storage capacity"
    if echo $USER1_PSWD | su - $USER1_NAME -c "whoami"; then
        info_msg "Successfull login to the user and execute command"
    else
        error_msg "FAIL: unable to login to the user execute command"
    fi

    info_msg "PASS"
}

postTest() {

    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

    # Delete the user that was created for the test
    del_user $USER1_NAME

    # stop audit service
    auditctl -D
    auditctl -e 0
    service auditd stop
    rm -f /var/log/audit/audit.log
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
