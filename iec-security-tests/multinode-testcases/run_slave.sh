#!/bin/bash

. ../lib/common-variables
. ../lib/multinode-comm-lib

CURPATH=$(pwd)

# Default values
: "${NET:=user}"
: "${SSH_PORT:=5577}"
: "${UN:=$USER1_NAME}"
: "${UN_PWD:=$USER1_PSWD}"
: "${CHRONY_PORT:=6644}"

execute_slave_script(){
    msg=$1
    testcase_id=$(parse_msg $msg 1)
    testcase_arg=$(parse_msg $msg 2)

    res="fail"
    if [ -f ${CURPATH}/$testcase_id/runTest-slave.sh ];then
        cd ${CURPATH}/$testcase_id
        eval ./runTest-slave.sh "$testcase_arg" && res="success"
    fi
}

init_msgid
while true; do
    wait_for_master_msg
    msg=$(parse_msg $MASTER_MSG 1)
    case $msg in
        "master_details")
            REMOTE_IP="$(parse_msg $MASTER_MSG 2)"
            REMOTE_UN="$(parse_msg $MASTER_MSG 3)"
            REMOTE_UN_PWD="$(parse_msg $MASTER_MSG 4)"
            REMOTE_SSH_PORT="$(parse_msg $MASTER_MSG 5)"
            save_remote_server_details $REMOTE_SERVER_DETAILS_FILE
            send_ack_to_master "success"
            ;;
        "get_slave_details")
            if [ "$NET" = "user" ]; then
                IP_ADDR="10.0.2.2"
            else
                ip link set enp0s2 up && ip addr
                IP_ADDR="$(ip addr | grep "state UP" -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
            fi
            send_ack_to_master $IP_ADDR $UN $UN_PWD $SSH_PORT $CHRONY_PORT
            ;;
        "stop")
            echo "Master request to stop"
            send_ack_to_master "success"
            break
            ;;
        *)
            echo "Other message=$msg"
            execute_slave_script $MASTER_MSG
            send_ack_to_master "success"
            ;;
    esac
done

echo "Server Stopped"
