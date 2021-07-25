#!/bin/bash
# Security Test case
# TC_CR2.11-RE1_1: Time synchronization
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables
. ../../lib/multinode-comm-lib

TEST_CASE_ID="$(basename $(pwd))"
TEST_CASE_NAME="TC_CR2.11-RE1_1: Time synchronization"
read_remote_server_details "../$REMOTE_SERVER_DETAILS_FILE"
CHRONY_CONF="/etc/chrony/chrony.conf"

preTest() {
    check_root
    check_pkgs_installed "chrony"

    # Take backup of configuration
    cp ${CHRONY_CONF} ./chrony.conf.bkp
    sed -i '/^pool/ s/^/#/' $CHRONY_CONF
    service chrony restart

    chronyc add server $REMOTE_IP port $CHRONY_PORT iburst minpoll 2

    info_msg "Configure Remote machine as a NTP time server"
    send_msg_to_server $TEST_CASE_ID "init"
}

runTest() {

    chronyc sources -a | cat

    info_msg "Change the time in DUT to some different time"
    ch_date=$(date -s "$(date | sed "s/$(date +"%Y")/$(expr $(date +"%Y") + 10)/g")")
    echo "modified date  "${ch_date}""
    ch_year="$(date +"%Y")"
    echo $ch_year

    info_msg "Check time is Synchronized to NTP time server"
    res=0
    for i in $(seq 12);do

        ! chronyc makestep && echo "chronyc makestep1 FAIL"
        new_year="$(date +"%Y")"
        echo $new_year
        if [ "${new_year}" != "${ch_year}" ];then
            res=1
            break
        fi

        sleep 5s
    done

    [ $res -eq 0 ] && error_msg "Failed to synchronize the time"

    info_msg "PASS"
}

postTest() {
    #Restore configuration
    [ -f chrony.conf.bkp ] && mv chrony.conf.bkp ${CHRONY_CONF}

    # stop service
    service chrony stop

    send_msg_to_server $TEST_CASE_ID "stop"
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