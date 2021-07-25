#!/bin/sh

CURPATH=`pwd`

RESULT_FILE="./result_file.txt"
if [ -f ${RESULT_FILE} ]; then
	mv ${RESULT_FILE} ${RESULT_FILE}".bkp"
else
	touch ${RESULT_FILE}
fi
echo "skip test: $SKIP_TESTS"
for f in *;
do
    [ ! -d ${CURPATH}/${f} ] && continue
    res="skip"
    dir=${f}
    echo $dir
    cd ${CURPATH}/${dir}
    if echo "$SKIP_TESTS" | grep -qw "$dir";then
        res="skip"
    elif [ -f ./runTest.sh ]; then
	    eval ./runTest.sh init && eval ./runTest.sh run
	    [ $? -eq 0 ] && res="pass" || res="fail"
	    eval ./runTest.sh clean
    fi
    echo "${dir}+$res" >> ${CURPATH}/${RESULT_FILE}
    which lava-test-case > /dev/null && lava-test-case ${dir} --result $res
done

