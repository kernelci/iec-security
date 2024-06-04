#!/bin/bash
# Security Test case
# TC_CR6.1_1: Programmatic access to audit logs

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR6.1_1: Programmatic access to audit logs"

AUDIT_CONF="/etc/audit/auditd.conf"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file =.*/max_log_file = 1/' $AUDIT_CONF
    sed -i 's/^space_left =.*/space_left = 20/' $AUDIT_CONF
    sed -i 's/^admin_space_left =.*/admin_space_left = 10/' $AUDIT_CONF

    # start audit service
    auditctl -e 1
    service auditd restart || tail -n 50 | journalctl
}

runTest() {

    # check ausearch read audit records
    if ausearch -m ALL > /dev/null; then
        info_msg "ausearch program is able to read audit records programatically"
    else
        error_msg "FAIL: ausearch program can not read audit records"
    fi

    # ausearch is audit utility application that will 
    # programmatically acces audit records 
    # Check if ausearch is linked to audit library
    if ldd /usr/sbin/ausearch | grep -q 'libaudit.so' ;then
        info_msg "ausearch program is linked with audit library"
    else
        error_msg "FAIL: ausearch program is not linked with audit library"
    fi

    info_msg "PASS"
}

postTest() {
    # Restore the audit configuration file
    [ -f auditd.conf.bkp ] && mv auditd.conf.bkp $AUDIT_CONF

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
