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

    echo "num_logs = 5" >> $AUDIT_CONF
    echo "max_log_file = 1" >> $AUDIT_CONF
    echo "max_log_file_action = rotate" >> $AUDIT_CONF
    echo "space_left = 20" >> $AUDIT_CONF
    echo "space_left_action = syslog" >> $AUDIT_CONF
    echo "admin_space_left = 10" >> $AUDIT_CONF
    echo "admin_space_left_action = syslog" >> $AUDIT_CONF
    
    # start audit service
    service auditd start
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