#!/bin/bash
# Security Test case
# TC_CR2.11-RE1_1: Unsuccessful remote login attempts - block ip address
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables
. ../../lib/multinode-comm-lib

TEST_CASE_ID="$(basename $(pwd))"
TEST_CASE_NAME="TC_CR1.11_3: Unsuccessful remote login attempts - block ip address"
read_remote_server_details "../$REMOTE_SERVER_DETAILS_FILE"

preTest() {
    check_root
    check_pkgs_installed "fail2ban" "nftables"

    # Restart Fail2ban and Nftables
    service fail2ban start
    service nftables start
}

runTest() {

	# Check IP is banned
	fail2ban-client status sshd
	if [ "${REMOTE_IP}" = "$(fail2ban-client status sshd | sed -n '$p' | cut -f2)" ];then
		info_msg "already ${REMOTE_IP} is banned, unban"
		fail2ban-client set sshd unbanip "${REMOTE_IP}"
	fi

    info_msg "Requsting remote device to attempt wrong login attempts"
    send_msg_to_slave $TEST_CASE_ID "do_failed_login_attempts"
    fail2ban-client status sshd
    if [ "${REMOTE_IP}" = "$(fail2ban-client status sshd | sed -n '$p' | cut -f2)" ];then
		info_msg "${REMOTE_IP} is banned"
    else
        error_msg "Failed: Can not ban the ip address"
    fi

    info_msg "PASS"
}

postTest() {
    # stop service
    systemctl stop fail2ban
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