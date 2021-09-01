#!/bin/bash
# Security Test case
# TC_CR3.4-RE1_1: Authenticity of software and information

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR3.4-RE1_1: Authenticity of software and information"

AIDE_CONF_FILE="/etc/aide/aide.conf"
AIDE_DB_FILE="/var/lib/aide/aide.db"

CONFIG_DATA="/etc/passwd VarFile"

preTest() {
    check_root
    check_pkgs_installed "aide" "acl"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # Backup original configuration
    cp $AIDE_CONF_FILE aide.conf.bkp

    # Disable including all aide.conf.d/*
    sed -i "/^@@x_include/ s/^#*/#/" "${AIDE_CONF_FILE}"

    # Create the aide database file
    if aide -c "${AIDE_CONF_FILE}" --init > /dev/null ;then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        info_msg "aide initialized successfully"
    else
        error_msg "FAIL: Cannot initialize aide"
    fi

}

runTest() {
    # The authenticity of the data after integrity check can be Verified 
    # by checking the authenticity of the aide software and the its configuration

    # check if aide configuration file can be accessed by unautherized user
    if ! echo "USER1_PSWD" | su - $USER1_NAME -c "echo '$CONFIG_DATA' \
                            >> $AIDE_CONF_FILE"; then
        info_msg "User got no permission to acces the aide configuration"
    else
        error_msg "FAIL: User has permission to access aide configuration file"
    fi

    if ! echo "USER1_PSWD" | su - $USER1_NAME -c "echo '$CONFIG_DATA' \
                            >> $AIDE_DB_FILE"; then
        info_msg "User got no permission to acces aide db file"
    else
        error_msg "FAIL: User has permission to access aide db file"
    fi

    # Give access permissions to user
    setfacl -m u:"${USER1_NAME}":rw "${AIDE_DB_FILE}"
    setfacl -m u:"${USER1_NAME}":rw "${AIDE_CONF_FILE}"

    # check if aide configuration file can be accessed by autherized user
    if echo "USER1_PSWD" | su - $USER1_NAME -c "echo $CONFIG_DATA \
                            >> $AIDE_CONF_FILE"; then
        info_msg "User got permission to acces the aide configuration"
    else
        error_msg "FAIL: User has not got permission to access the configuration file"
    fi

    if echo "USER1_PSWD" | su - $USER1_NAME -c "echo '$CONFIG_DATA' \
                            >> $AIDE_DB_FILE"; then
        info_msg "User got permission to acces aide db file"
    else
        error_msg "FAIL: User has not got permission to access aide db file"
    fi

    info_msg "PASS"
}

postTest() {

    setfacl -nb ${AIDE_DB_FILE}
    setfacl -nb ${AIDE_CONF_FILE}

    # restore original aide configuration
    mv aide.conf.bkp $AIDE_CONF_FILE

    # Delete the user that was created for the test
    del_user $USER1_NAME
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
