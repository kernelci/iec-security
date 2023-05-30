#!/bin/bash
# Security Test case
# TC_CR2.8_1: Auditable events - categories

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.8_1: Auditable events - categories"

AUREPORT_ACC_CHANGES_FIELD="Number of changes to accounts, groups, or roles: "
AUREPORT_CFG_CHANGES_FIELD="Number of changes in configuration: "
AUDIT_CONF="/etc/audit/auditd.conf"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 5/' $AUDIT_CONF
    sed -i 's/^max_log_file =.*/max_log_file = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file_action =.*/max_log_file_action = rotate/' $AUDIT_CONF
    sed -i 's/^space_left =.*/space_left = 20/' $AUDIT_CONF
    sed -i 's/^space_left_action =.*/space_left_action = syslog/' $AUDIT_CONF
    sed -i 's/^admin_space_left =.*/admin_space_left = 10/' $AUDIT_CONF
    sed -i 's/^admin_space_left_action =.*/admin_space_left_action = syslog/' $AUDIT_CONF

    auditctl -e 1
    service auditd restart
}

runTest() {

    # Delete any rules already present
    auditctl -D

    # Add rules
    # to record control system events
    auditctl -w /etc/hosts -p wa -k control-system-event
    auditctl -w /etc/hostname -p wa -k control-system-event

    # to record any access control failures
    auditctl -a always,exit -S all -F exit=-EACCES -k file_access_denied

    start_time="$(date +"%m/%d/%y %T")"
    cnfg_changes_bfr=$(ausearch -i --start $start_time -m USYS_CONFIG,CONFIG_CHANGE | wc -l)
    cntrl_sys_evnts_bfr=$(ausearch -i --start $start_time -k "control-system-event" | wc -l)
    access_cntrl_bfr=$(ausearch -i --start $start_time -k "file_access_denied" | wc -l)
    audit_log_evnts_bfr=$(ausearch -i --start $start_time | wc -l)

    # Do some system control changes
    echo "0.0.0.0 example.com" >> /etc/hosts

    # Do some access control failure
    echo "$USER1_PSWD" | su - $USER1_NAME -c "cat /etc/shadow | cat"

    # Do some config changes
    auditctl -a always,exit -S adjtimex,settimeofday -F key=control-system-event

    cnfg_changes_aft=$(ausearch -i --start $start_time -m USYS_CONFIG,CONFIG_CHANGE | wc -l)
    cntrl_sys_evnts_aft=$(ausearch -i --start $start_time -k "control-system-event" | wc -l)
    access_cntrl_aft=$(ausearch -i --start $start_time -k "file_access_denied" | wc -l)
    audit_log_evnts_aft=$(ausearch -i --start $start_time | wc -l) 

    echo "config changes: before=$cnfg_changes_bfr, after=$cnfg_changes_aft"
    echo "control system events: before=$cntrl_sys_evnts_bfr, after=$cntrl_sys_evnts_aft"
    echo "access control events: before=$access_cntrl_bfr, after=$access_cntrl_aft"
    echo "audit log events: before=$audit_log_evnts_bfr, after=$audit_log_evnts_aft"

    if [ $cnfg_changes_aft -gt $cnfg_changes_bfr ] && \
        [ $cntrl_sys_evnts_aft -gt $cntrl_sys_evnts_bfr ] && \
        [ $access_cntrl_aft -gt $access_cntrl_bfr ] && \
        [ $audit_log_evnts_aft -gt $audit_log_evnts_bfr ]; then
        info_msg "Found audit changes"
    else
        error_msg "FAIL: can not find audit event changes"
    fi

    info_msg "PASS"
}

postTest() {
    sed -i '/example.com/d' /etc/hosts

    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

    # Delete the user that was created for the test
    del_user $USER1_NAME

    # Stop the audit service
    auditctl -D
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
