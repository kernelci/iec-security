#!/bin/bash
# Security Test case
# TC_CR7.1_1: Validate Denial of service protection

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR7.1_1: Validate Denial of service protection"

SYSLOG="/var/log/syslog"
DROP_LOG="drop_rate_limit"
FIREWALL_RULE="icmp type echo-request limit rate over 3/second log prefix \"${DROP_LOG}\" drop"

preTest() {
    check_root
    check_pkgs_installed "nftables"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    info_msg "Start nftables service"
    service nftables start

    info_msg "Add a firewall rule"
    nft add rule inet filter input "${FIREWALL_RULE}"
}

runTest() {
    log_msg="start-test-$(date +%s)"
    logger $log_msg

    # Flood ping request
    info_msg "Flodding ping request to Create DoS attack"
    ping -n -i 0.3 -c 100 127.0.0.1 > /dev/null 2>&1
    sleep 1s

    info_msg "Check syslog wheather ip rules dropping flooded messages"
    sed -n "/$log_msg/,/$DROP_LOG_PREFIX/p" $SYSLOG
    log_msg_cnt=$(sed -n "/$log_msg/,/$DROP_LOG_PREFIX/p" $SYSLOG | wc -l)
    if [ $log_msg_cnt -gt 1 ]; then
        info_msg "Successfully droped DoS attacks"
    else
        error_msg "FAIL: Could not drop DoS attack"
    fi

    info_msg "PASS"
}

postTest() {
    # Delete the user that was created for the test
    del_user $USER1_NAME

    info_msg "Delete the firewall rule"
    for i in $(nft --handle --numeric list chain inet filter input | grep "${FIREWALL_RULE}"| awk -F '# handle ' '{print $2}')
    do
        echo "delete handle number ${i}"
        ! nft delete rule inet filter input handle "${i}" && echo "failed to delete rule"
    done

    # Stop nftables service
    service nftables stop
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
