#!/bin/bash

. ../lib/multinode-comm-lib
CURPATH=$(pwd)

echo "Remote ip addr: $SERVER_IP"
echo "Remote username: $SERVER_UN"
echo "Remote password: $SERVER_UN_PWD"
if [ -z ${SERVER_IP} ] || [ -z ${SERVER_UN} ] || [ -z ${SERVER_UN_PWD} ];then
        echo "Ip address or username or password can not be empty"
        exit 1
fi

REMOTE_IP="$SERVER_IP"
REMOTE_UN="$SERVER_UN"
REMOTE_UN_PWD="$SERVER_UN_PWD"
REMOTE_SSH_PORT="$SERVER_SSH_PORT"
save_remote_server_details $REMOTE_SERVER_DETAILS_FILE

for dir in *;
do
	[ ! -d ${CURPATH}/${dir} ] && continue
	echo $dir
	cd ${CURPATH}/${dir}
	res="skip"
    if echo "$SKIP_TESTS" | grep -qw "$dir";then
        res="skip"
    elif [ -f ./runTest-client.sh ]; then
	    eval ./runTest-client.sh init && eval ./runTest-client.sh run && res="pass" || res="fail"
	    eval ./runTest-client.sh clean
    fi
	which lava-test-case > /dev/null && lava-test-case ${dir} --result $res
done

echo "Test Done"
