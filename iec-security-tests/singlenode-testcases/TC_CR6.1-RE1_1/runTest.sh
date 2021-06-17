#!/bin/bash
# Security Test case
# TC_CR6.1_1: Programmatic access to audit logs

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR6.1_1: Programmatic access to audit logs"

preTest() {
    check_root
    check_pkgs_installed "auditd"

    # start audit service
    service auditd start
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