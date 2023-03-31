#!/bin/bash
# Security Test case
# TC_CR1.11_3: Unsuccessful remote login attempts - block ip address
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables
. ../../lib/multinode-comm-lib

read_remote_server_details "../$REMOTE_SERVER_DETAILS_FILE"

if [ "$1" == "do_failed_login_attempts" ]; then
    
    i=0
    while [ $i -lt 3 ]
    do
            i=$((i+1))
            echo "attempt failed login ip = $REMOTE_IP port = $REMOTE_SSH_PORT $i"
            sshpass -p "wrong_pwd" ssh -o StrictHostKeyChecking=no -p ${REMOTE_SSH_PORT} ${REMOTE_UN}@${REMOTE_IP} 'whoami' || true
    done  
fi
