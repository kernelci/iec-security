#!/bin/bash
# TC_CR1.9_3: Strength of public key-based authentication
# - check certificate's revocation status

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.9_2: Strength of public key-based authentication \
- check certificate's revocation status"

tmp_dir="tmp_ssh_cert"
sshd_config="/etc/ssh/sshd_config"

preTest() {
    check_root
    check_pkgs_installed "openssh-server"

    mkdir $tmp_dir

    # Create CA keys
    ssh-keygen -q -t rsa -f $tmp_dir/ca -P ''

    # Configure remote server with user CA public key
    echo "emergency" > /etc/ssh/principals
    echo "sshuser" >> /etc/ssh/principals
    cp $tmp_dir/ca.pub /etc/ssh/ca.pub
    sed -i '/^TrustedUserCAKeys/d' $sshd_config
    sed -i '/^AuthorizedPrincipalsFile/d' $sshd_config
    sed -i '/^RevokedKeys/d' $sshd_config
    echo "TrustedUserCAKeys /etc/ssh/ca.pub" >> $sshd_config
    echo "AuthorizedPrincipalsFile /etc/ssh/principals" >> $sshd_config
    touch /etc/ssh/revoked_keys
    echo "RevokedKeys /etc/ssh/revoked_keys" >> $sshd_config
    service sshd restart

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {

    # Create user keys
    ssh-keygen -q -t rsa -P '' -f ~/.ssh/id_rsa <<< y

    # Generate user certificate
    ssh-keygen -s $tmp_dir/ca -I $(whoami) -n 'sshuser' -z 1 ~/.ssh/id_rsa.pub

    # Add to known_hosts
    echo "@cert-authority * $(cat $tmp_dir/ca.pub)" > ~/.ssh/known_hosts

    # Verify authentication with certificate
    msg=$(ssh \
            -o LogLevel=INFO \
            -o PreferredAuthentications=publickey \
            -o StrictHostKeyChecking=no \
            $USER1_NAME@127.0.0.1 'whoami' | cat)
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "Successfully login with valid certificate"
    fi

    # Revok the certificate
    if ssh-keygen -kf /etc/ssh/revoked_keys -z 1 ~/.ssh/id_rsa.pub; then
        info_msg "Added user certificate to reocation list"
    else
        error_msg "FAIL: cannot add user certificate revocaton list"
    fi

    # Verify whether ssh authentication checks the revocation certificate
    msg=$(ssh \
            -o LogLevel=INFO \
            -o PreferredAuthentications=publickey \
            -o StrictHostKeyChecking=no \
            $USER1_NAME@127.0.0.1 'whoami' | cat)
    if [ "$msg" = "$USER1_NAME" ]; then
        error_msg "FAIL: SSH authentication can not check revocation status"
    else
        info_msg "Successfully verified revocation status"
    fi

    info_msg "PASS"
}

postTest() {
    rm -rf $tmp_dir

    rm /etc/ssh/principals
    rm /etc/ssh/ca.pub
    sed -i '/^@cert-authority*/d' ~/.ssh/known_hosts
    sed -i '/^TrustedUserCAKeys/d' $sshd_config
    sed -i '/^AuthorizedPrincipalsFile/d' $sshd_config
    sed -i '/^RevokedKeys/d' $sshd_config
    service sshd restart

    # delete the user created in the test
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