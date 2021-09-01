#!/bin/bash
# Security Test case
# TC_CR2.11-RE1_1: Time synchronization
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables
. ../../lib/multinode-comm-lib

read_remote_server_details "../$REMOTE_SERVER_DETAILS_FILE"

CHRONY_CONF="/etc/chrony/chrony.conf"

if [ "$1" = "init" ]; then
    info_msg "Configure Remote machine as a NTP time server"

    # Take backup of configuration
    cp ${CHRONY_CONF} ./chrony.conf.bkp
    echo local stratum 10 >> ${CHRONY_CONF}
    echo manual >> ${CHRONY_CONF}
    echo "allow $REMOTE_IP" >> ${CHRONY_CONF}

    service chrony restart

    # Check client NTP access
    chronyc accheck $REMOTE_IP

elif [ "$1" = "stop" ]; then
    info_msg "clean chrony "
    echo "Remove Ntp time server configuration"
    #Restore configuration
    [ -f chrony.conf.bkp ] && mv chrony.conf.bkp ${CHRONY_CONF}

    service chrony stop
fi

info_msg "Done"
