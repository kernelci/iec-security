#!/bin/bash

. ../lib/multinode-comm-lib

#CLIENT_IP="127.0.0.1"
#CLIENT_UN="skelios"
#CLIENT_UN_PWD="IEC-62443"
#CLIENT_SSH_PORT=""

#SERVER_IP="127.0.0.1"
#SERVER_UN="skelios"
#SERVER_UN_PWD="IEC-62443"
#SERVER_SSH_PORT=""
CURPATH=$(pwd)

echo "client ip addr: $CLIENT_IP"
echo "client ssh port: $CLIENT_SSH_PORT"

REMOTE_IP="$CLIENT_IP"
REMOTE_UN="$CLIENT_UN"
REMOTE_UN_PWD="$CLIENT_UN_PWD"
REMOTE_SSH_PORT="$CLIENT_SSH_PORT"
save_remote_server_details "remote-server-details.conf"

execute_server_script(){
    msg=$1
    testcase_id=$(parse_msg $msg 1)
    testcase_arg=$(parse_msg $msg 2)

    res="fail"
    if [ -f ${CURPATH}/$testcase_id/runTest-server.sh ];then
        cd ${CURPATH}/$testcase_id
        eval ./runTest-server.sh "$testcase_arg" && res="success"
    fi
}

init_msgid
while true; do
    wait_for_client_msg
    msg=$(parse_msg $CLIENT_MSG 1)
    case $msg in
        "send_client_details")
            CLIENT_IP="$(parse_msg $CLIENT_MSG 2)"
            CLIENT_UN="$(parse_msg $CLIENT_MSG 3)"
            CLIENT_UN_PWD="$(parse_msg $CLIENT_MSG 4)"
            send_ack_to_client "success"
            ;;
        "get_server_details")
            ip link set enp0s2 up && ip addr
            SERVER_IP_ADDR="$(ip addr | grep "state UP" -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
            send_ack_to_client $SERVER_IP $SERVER_UN $SERVER_UN_PWD
            ;;
        "stop")
            echo "Client request to stop"
            send_ack_to_client "success"
            break
            ;;
        *)
            echo "Other message=$msg"
            execute_server_script $CLIENT_MSG
            send_ack_to_client "success"
            ;;
    esac
done

echo "Server Stopped"
