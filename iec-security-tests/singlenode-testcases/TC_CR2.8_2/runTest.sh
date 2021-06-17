#!/bin/bash
# Security Test case
# TC_CR2.8_2: Auditable events - data fields
#

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR2.8_2: Auditable events - data fields"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # start audit service
    service auditd start
}

runTest() {

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    audit_record=$(ausearch -m ADD_USER | tail -2)
    time_stamp=$(echo $audit_record | sed -n 's/.*time->\(.*\).*type=.*/\1/p')
    type_val=$(echo $audit_record | sed -n 's/.*type=\(.*\)/\1/p' | cut -d " " -f 1)
    pid_val=$(echo $audit_record | sed -n 's/.*pid=\(.*\)/\1/p' | cut -d " " -f 1)
    user_id_val=$(echo $audit_record | sed -n 's/.*auid=\(.*\)/\1/p' | cut -d " " -f 1)
    res_val=$(echo $audit_record | sed -n 's/.*res=\(.*\)/\1/p' | cut -d " " -f 1)

    info_msg "audit record data fields: "
    echo "time stamp: $time_stamp"
    echo "type: $type_val"
    echo "pid: $pid_val"
    echo "user id: $user_id_val"
    echo "result: $res_val"
    if [ -z "$time_stamp" ] || [ -z "$type_val" ] || [ -z "$pid_val" ] ||\
        [ -z "$user_id_val" ] || [ -z "$res_val" ]; then
        error_msg "FAIL: some of the data fields are not recorded"
    fi

    info_msg "PASS"
}

postTest() {

    # Delete the user that was created for the test
    del_user $USER1_NAME

    # stop audit service
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