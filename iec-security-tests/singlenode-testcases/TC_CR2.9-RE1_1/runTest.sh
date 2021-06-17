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

    # Configure audit storage values
    # backup previous settings
    sed -i 's/^num_logs =/###@num_logs =/' $AUDIT_CONF
    sed -i 's/^max_log_file =/###@max_log_file =/' $AUDIT_CONF
    sed -i 's/^max_log_file_action =/###@max_log_file_action =/' $AUDIT_CONF
    sed -i 's/^space_left =/###@space_left =/' $AUDIT_CONF
    sed -i 's/^space_left_action =/###@space_left_action =/' $AUDIT_CONF
    sed -i 's/^admin_space_left =/###@admin_space_left =/' $AUDIT_CONF
    sed -i 's/^admin_space_left_action =/###@admin_space_left_action =/' $AUDIT_CONF

    echo "num_logs = 1" >> $AUDIT_CONF
    echo "max_log_file = 1" >> $AUDIT_CONF
    echo "max_log_file_action = syslog" >> $AUDIT_CONF
    echo "space_left = 20" >> $AUDIT_CONF
    echo "space_left_action = syslog" >> $AUDIT_CONF
    echo "admin_space_left = 10" >> $AUDIT_CONF
    echo "admin_space_left_action = syslog" >> $AUDIT_CONF
    
    # start audit service
    service auditd restart
}

runTest() {

    # add audit rules to fill the audit storage
    auditctl -D
    auditctl -w /etc/passwd -p r -k control-system-event
    auditctl -a always,exit -F arch=b64 -S creat,open,openat,open_by_handle_at,truncate,ftruncate -k file_access_denied

    # trigger audit events
    log_msg="start-test-$(date +%s)"
    logger "$log_msg"
    while true; do
        cat /etc/passwd > /dev/null
        audit_size=$(ls -l /var/log/audit/audit.log | awk '/audit.log$/ {print $5}')
        if [ $audit_size -gt 1048576 ];then
            break
        fi
    done
    echo "audit_size: $audit_size"

    sleep 1s
    audit_failure_msg="Audit daemon log file is larger than max size"
    log_msg_cnt=$(sed -n "/$log_msg/,/$audit_failure_msg/p" $SYSLOG | wc -l)
    if [ $log_msg_cnt -gt 1 ]; then
        info_msg "Warning message sent when Audit storage capacity is exceeded"
    else
        error_msg "FAIL: Not recieved warning message of Audit storage capacity is exceeded"
    fi

    info_msg "PASS"  
}

postTest() {

    # restore previous configuration
    if grep -q "^###@max_log_file =" $AUDIT_CONF; then
        sed -i '/^max_log_file =/d' $AUDIT_CONF
        sed -i 's/^###@max_log_file =/max_log_file =/' $AUDIT_CONF
    fi
    if grep -q "^###@max_log_file_action =" $AUDIT_CONF; then
        sed -i '/^max_log_file_action =/d' $AUDIT_CONF
        sed -i 's/^###@max_log_file_action =/max_log_file_action =/' $AUDIT_CONF
    fi
    if grep -q "^###@space_left =" $AUDIT_CONF; then
        sed -i '/^space_left =/d' $AUDIT_CONF
        sed -i 's/^###@space_left =/space_left =/' $AUDIT_CONF
    fi
    if grep -q "^###@space_left_action =" $AUDIT_CONF; then
        sed -i '/^space_left_action =/d' $AUDIT_CONF
        sed -i 's/^###@space_left_action =/space_left_action =/' $AUDIT_CONF
    fi
    if grep -q "^###@admin_space_left =" $AUDIT_CONF; then
        sed -i '/^admin_space_left =/d' $AUDIT_CONF
        sed -i 's/^###@admin_space_left =/admin_space_left =/' $AUDIT_CONF
    fi
    if grep -q "^###@admin_space_left_action =" $AUDIT_CONF; then
        sed -i '/^admin_space_left_action =/d' $AUDIT_CONF
        sed -i 's/^###@admin_space_left_action =/admin_space_left_action =/' $AUDIT_CONF
    fi

    # stop audit service
    auditctl -D
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
