#!/bin/bash
# TC_CR1.8_1: Validate Authentication with public key infrastructure
#

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.8_1: Validate Authentication with public key infrastructure"

tmp_dir="tmp_ssh_cert"
sshd_config="/etc/ssh/sshd_config"

preTest() {
    check_root
    check_pkgs_installed "openssh-server"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # Create temporary directory for the ssh keys
    mkdir $tmp_dir
    # commenting out keyboard-interactive string in sshd_config file to validate public key infrastruture Test-Case
    sed -i '/^AuthenticationMethods keyboard-interactive$/s/^/#/' $sshd_config
    # restart the ssh service
    service sshd restart
}

runTest() {

    # Create user keys
    ssh-keygen -q -t rsa -P '' -f $tmp_dir/id_rsa <<< y

    # copy certificate to the user
    sshpass -p $USER1_PSWD ssh-copy-id \
                                -o StrictHostKeyChecking=no \
                                -i $tmp_dir/id_rsa  \
                                $USER1_NAME@127.0.0.1

    # Verify user authentication with ssh keys
    msg=$(ssh \
            -i $tmp_dir/id_rsa \
            -o PreferredAuthentications=publickey \
            -o StrictHostKeyChecking=no \
            $USER1_NAME@127.0.0.1 'whoami' | cat)
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "Successfully verified public key authentication"
    else
        error_msg "FAIL: public key authentication is failed"
    fi

    info_msg "PASS"
}

postTest() {
    # delete temp directory
    [ -d $tmp_dir ] && rm -rf $tmp_dir

    # delete the user created in the test
    del_user $USER1_NAME

    # uncommenting keyboard-interactive string in sshd_config file after validating public key infrastruture Test-Case
    sed '/AuthenticationMethods keyboard-interactive/s/^#//g' -i $sshd_config
    # restart the ssh service
    service sshd restart
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
