#!/bin/bash

# Security Test case
# TC_CR4.1_2: Information confidentiality - at rest using TPM Secure storage
# In this test case, the tpm device existence in the system is verified and
# whether home partition is crypto LUKS type.


set -e
. ../../lib/common-lib
. ../../lib/common-variables


TEST_CASE_NAME="TC_CR4.1_2: Information confidentiality - at rest using Secure storage"

preTest() {
    check_root
}

runTest() {

    # Check whether the TPM device on
    if [ $(cat /sys/class/tpm/tpm*/tpm_version_major) -gt 0 ]; then
        info_msg "TPM is on"
    else
        error_msg "TPM is not enabled"
    fi

    # Check /home partition is crypto LUKS type
    disktype=$(blkid -t PARTLABEL=home | awk '{print $3}')
    if "${disktype}" == "crypto_LUKS"; then
        info_msg "Confirmed the crypt partitions"
    else
        error_msg "Not confirmed the crypt partitions"
    fi
    info_msg "PASS"
}

postTest() {

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

