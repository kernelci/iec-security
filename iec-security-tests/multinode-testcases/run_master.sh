#!/bin/bash

. ../lib/common-variables
. ../lib/multinode-comm-lib
CURPATH=`pwd`

# Default values
: "${NET:=user}"
: "${SSH_PORT:=5555}"
: "${UN:=$USER1_NAME}"
: "${UN_PWD:=$USER1_PSWD}"

# Send master details to slave
if [ "$NET" = "user" ]; then
	IP_ADDR="10.0.2.2"
else
	ip link set enp0s2 up && ip addr
	IP_ADDR="$(ip addr | grep "state UP" -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
fi
send_msg_to_slave "master_details" "$IP_ADDR" "$UN" "$UN_PWD" "$SSH_PORT"

# Get slave details
send_msg_to_slave "get_slave_details"
REMOTE_IP="$(parse_msg $SLAVE_RESP 1)"
REMOTE_UN="$(parse_msg $SLAVE_RESP 2)"
REMOTE_UN_PWD="$(parse_msg $SLAVE_RESP 3)"
REMOTE_SSH_PORT="$(parse_msg $SLAVE_RESP 4)"
REMOTE_CHRONY_PORT="$(parse_msg $SLAVE_RESP 5)"
save_remote_server_details $REMOTE_SERVER_DETAILS_FILE

for dir in *;
do
	[ ! -d ${CURPATH}/${dir} ] && continue
	echo $dir
	cd ${CURPATH}/${dir}
	res="skip"
    if echo "$SKIP_TESTS" | grep -qw "$dir";then
        res="skip"
    elif [ -f ./runTest-master.sh ]; then
	    eval ./runTest-master.sh init && eval ./runTest-master.sh run && res="pass" || res="fail"
	    eval ./runTest-master.sh clean
    fi
	which lava-test-case > /dev/null && lava-test-case ${dir} --result $res
done

echo "Test Done"
