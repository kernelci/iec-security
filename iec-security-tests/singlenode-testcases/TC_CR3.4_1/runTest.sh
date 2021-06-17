#!/bin/bash
# Security Test case
# TC_CR3.4_1: Software and information integrity

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR3.4_1: Software and information integrity"

SAMPLE_APP_DIR="$(pwd)/testapp"
TEST_FILE="$SAMPLE_APP_DIR/test.conf"
AIDE_CONF_FILE="/etc/aide/aide.conf"
TEST_FILE_DATA="Hi there"

AIDE_FOUND_NO_DIFF_MSG="AIDE found NO differences between database and filesystem. Looks okay!!"
AIDE_FOUND_DIFF_MSG="AIDE found differences between database and filesystem!!"

preTest() {
    check_root
    check_pkgs_installed "aide"

    # Create sample test file for integrity check
    [ ! -d $SAMPLE_APP_DIR ] && mkdir -p $SAMPLE_APP_DIR
    [ ! -f $TEST_FILE ] && touch $TEST_FILE
    echo $TEST_FILE_DATA > $TEST_FILE

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

    info_msg "PASS"
}

postTest() {
    # Remove sample contents created
    rm -rf $SAMPLE_APP_DIR

    # Remove aide configuration
    sed -i "/${TEST_FILE//\//\\/}/d" $AIDE_CONF_FILE
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