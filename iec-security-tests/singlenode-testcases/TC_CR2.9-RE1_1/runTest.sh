#!/bin/bash
# Security Test case
# TC_CR2.9-RE1_1: Warn when audit record storage capacity threshold reached
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.9-RE1_1: Warn when audit record storage capacity threshold reached"

AUDIT_CONF="/etc/audit/auditd.conf"
SYSLOG="/var/log/syslog"

preTest() {
    check_root
    check_pkgs_installed "syslog-ng-core" "auditd"

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
    service auditd restart
}

runTest() {

    log_msg="start-test-$(date +%s)"
    logger "$log_msg"

    avail_space=$(df --output=avail /var | tail -1)
    threshold_value=$((avail_space-4096))
    info_msg "Available space: $avail_space"
    if [ $threshold_value -lt 5120 ]; then
        error_msg "The available free space is very low to perform test"
    fi

    info_msg "Configure audit storage threshold value: $threshold_value"
    sed -i "s/^space_left =.*/space_left = $threshold_value/" $AUDIT_CONF
    service auditd restart

    info_msg "Fill up the storage to reach threshold value"
    dd if=/dev/zero of=file_5mb bs=5MB count=1

    # add audit rules to fill the audit storage
    auditctl -D
    auditctl -w /etc/passwd -p r -k control-system-event
    auditctl -a always,exit -F arch=b64 -S all -k file_access_denied
    cat /etc/passwd > /dev/null
    # trigger audit events

    sleep 1s
    audit_failure_msg="Audit daemon is low on disk space for logging"
    log_msg_cnt=$(sed -n "/$log_msg/,/$audit_failure_msg/p" $SYSLOG | wc -l)
    if [ $log_msg_cnt -gt 1 ]; then
        info_msg "Warning message is sent to syslog when audit storage threshold is reached"
    else
        error_msg "FAIL: Not recieved warning message of Audit storage threshold is reached"
    fi

    info_msg "PASS"  
}

postTest() {

    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

    [ -f file_5mb ] && rm file_5mb

    # stop audit service
    auditctl -D
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
