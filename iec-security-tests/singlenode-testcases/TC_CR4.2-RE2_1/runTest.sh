#!/bin/bash
# Security Test case
# TC_CR4.2-RE1_1: Erase of shared memory resources
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR4.2-RE1_1: Erase of shared memory resources"

preTest() {
    check_root
    check_pkgs_installed "util-linux"
}

runTest() {

    # Create shared memory resource
    shmid=$(ipcmk -M 1024 | cut -d: -f2)
    echo "$shmid"
    if [ "$shmid" ];then
        info_msg "Shared memory resource is created $shmid"
    else
        error_msg "FAIL: Cannot create shared memory resource"
    fi

    # Remove shared memory resource
    if ipcrm -m ${shmid}; then
        info_msg "Shared memory resource is removed successfully"
    else
        error_msg "FAIL: Cannot delete shared memory resource"
    fi

    info_msg "PASS"
}

postTest() {
    echo ""
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
