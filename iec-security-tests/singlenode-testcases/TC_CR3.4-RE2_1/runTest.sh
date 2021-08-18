#!/bin/bash
# Security Test case
# TC_CR3.4-RE2_1: Automated notification of integrity violations

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR3.4-RE2_1: Automated notification of integrity violations"

SAMPLE_APP_DIR="$(pwd)/testapp"
TEST_FILE="$SAMPLE_APP_DIR/test.conf"
AIDE_CONF_FILE="/etc/aide/aide.conf"
SYSLOG="/var/log/syslog"

AIDE_FOUND_NO_DIFF_MSG="AIDE found NO differences between database and filesystem. Looks okay!!"
AIDE_FOUND_DIFF_MSG="AIDE found differences between database and filesystem!!"

preTest() {
    check_root
    check_pkgs_installed "aide"

    # Create sample test file for integrity check
    [ ! -d $SAMPLE_APP_DIR ] && mkdir -p $SAMPLE_APP_DIR
    [ ! -f $TEST_FILE ] && touch $TEST_FILE
    echo "Hi there" > $TEST_FILE

	# Add the application file to aide integrity check
	if [ ! $(grep -q "$TEST_FILE  VarFile"  ${AIDE_CONF_FILE}) ];then
		echo "$TEST_FILE  VarFile" >> "${AIDE_CONF_FILE}"
	fi

	# Create the aide database file
	if aide -c "${AIDE_CONF_FILE}" --init > /dev/null ;then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        info_msg "aide initialized successfully"
    else
        error_msg "FAIL: Cannot initialize aide"
    fi
}

runTest() {

    # check any differences found 
    aide_check=$(aide -c $AIDE_CONF_FILE -C | cat)
    if echo "$aide_check" | grep -q "$AIDE_FOUND_NO_DIFF_MSG"; then
        info_msg "Found no differences in aide check"
    else
        error_msg "FAIL: Found differences in aide check, something wrong"
    fi

    # Do changes to the file
    if chmod 0777 $TEST_FILE; then
        info_msg "Changed file permission of the test file"
    else
        error_msg "FAIL: Cannot modify permission of the test file"
    fi

    # check if aide detect the integrity failures
    aide_check=$(aide -c $AIDE_CONF_FILE -C | cat)
    if echo "$aide_check" | grep -q "$AIDE_FOUND_DIFF_MSG"; then
        info_msg "AIDE found integrity failures"
    else
        error_msg "FAIL: AIDE could not detect integrity failures"
    fi

    # report integrity failures to syslog
    # alt: can also report to mail
    log_msg="start-test-$(date +%s)"
    logger $log_msg
    aide -c $AIDE_CONF_FILE -u --report=syslog > /dev/null | cat

    sleep 1s
    log_msg_cnt=$(sed -n "/$log_msg/,/$AIDE_FOUND_DIFF_MSG/p" $SYSLOG | wc -l)
    if [ $log_msg_cnt -gt 1 ]; then
        info_msg "Found aide report in syslog"
    else
        error_msg "FAIL: Aide could not reprot"
    fi

    info_msg "PASS"
}

postTest() {
    # Remove sample contents created
    rm -rf $SAMPLE_APP_DIR

    # remove aide configuration
    sed -i "/${TEST_FILE//\//\\/}/d" $AIDE_CONF_FILE

    # Remove aide DB files
    [ -f /var/lib/aide/aide.db.new ] && rm -f /var/lib/aide/aide.db.new
    [ -f /var/lib/aide/aide.db ] && rm -f /var/lib/aide/aide.db
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
