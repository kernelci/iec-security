#!/bin/bash
# Security Test case
# TC_CR6.1_1: Audit log accessibility

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR6.1_1: Audit log accessibility"

AUDIT_FILE="/var/log/audit/audit.log"
AUDIT_DIR="/var/log/audit"
AUDIT_CONF="/etc/audit/auditd.conf"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # Backup the audit configuration file
    cp $AUDIT_CONF auditd.conf.bkp

    # Configure audit storage values
    sed -i 's/^num_logs =.*/num_logs = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file =.*/max_log_file = 1/' $AUDIT_CONF
    sed -i 's/^max_log_file_action =.*/max_log_file_action = rotate/' $AUDIT_CONF
    sed -i 's/^space_left =.*/space_left = 20/' $AUDIT_CONF
    sed -i 's/^space_left_action =.*/space_left_action = syslog/' $AUDIT_CONF
    sed -i 's/^admin_space_left =.*/admin_space_left = 10/' $AUDIT_CONF
    sed -i 's/^admin_space_left_action =.*/admin_space_left_action = syslog/' $AUDIT_CONF

    # start audit service
    auditctl -e 1
    service auditd restart

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # Check user1 has permission to read audit log
    check_msg=$(echo $USER1_PSWD | su - $USER1_NAME -c "cat $AUDIT_FILE | wc -l")
    if [ $check_msg -gt 0 ];then
        info_msg "User has permission to read audit logs"
    else
        info_msg "User has no permission to read audit logs"
    fi

    # Provide the accessible permissions for audit logs to user
    setfacl -m u:"${USER1_NAME}":r-x "${AUDIT_DIR}"
    setfacl -m u:"${USER1_NAME}":r "${AUDIT_FILE}"

    # Check user got permission to read audit logs
    check_msg=$(echo $USER1_PSWD | su - $USER1_NAME -c "cat $AUDIT_FILE | wc -l")
    if [ $check_msg -gt 0 ];then
        info_msg "User has permission to read audit logs"
    else
        error_msg "FAIL: User has no permission to read audit logs"
    fi

    # Check user1 should not have write permission aswell
    if ! echo $USER1_PSWD | su - $USER1_NAME -c "echo 1 >> $AUDIT_FILE" ; then
        info_msg "User has no wirte permission to audit logs"
    else
        error_msg "FAIL: User has permission to write audit logs"
    fi

    setfacl -nb $AUDIT_DIR
    info_msg "PASS"
}

postTest() {
    setfacl -nb $AUDIT_DIR

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
