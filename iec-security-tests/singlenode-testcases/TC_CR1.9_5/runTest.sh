#!/bin/bash
# TC_CR1.9_5: Strength of public key-based authentication
# - map authenticated identity to a user
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.9_5: Strength of public key-based authentication \
- map authenticated identity to a user"

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
    create_test_user $USER2_NAME $USER2_PSWD
    create_test_user $USER3_NAME $USER3_PSWD
}

runTest() {

    # Create ssh key pair for user1
    if echo "$USER1_PSWD" | su - $USER1_NAME -c \
                            "ssh-keygen -q -t rsa -P '' -f ~/.ssh/id_rsa <<< y"; then
        info_msg "Create ssh key pair for $USER1_NAME"
    else
        error_msg "FAIL: Unable to create ssh key pair for $USER1_NAME"
    fi

    # Create ssh key pair for user2
    if echo "$USER2_PSWD" | su - $USER2_NAME -c \
                            "ssh-keygen -q -t rsa -P '' -f ~/.ssh/id_rsa <<< y"; then
        info_msg "Create ssh key pair for $USER2_NAME"
    else
        error_msg "FAIL: Unable to create ssh key pair for $USER2_NAME"
    fi

    # Copy user public keys to local
    cp /home/$USER1_NAME/.ssh/id_rsa.pub $tmp_dir/user1.pub
    cp /home/$USER2_NAME/.ssh/id_rsa.pub $tmp_dir/user2.pub

    # Generate user certificate for USER1
    ssh-keygen -s $tmp_dir/ca -I $USER1_NAME -n 'sshuser' -z 1 $tmp_dir/user1.pub
    ssh-keygen -s $tmp_dir/ca -I $USER2_NAME -n 'sshuser' -z 2 $tmp_dir/user2.pub

    # wrongly map user certificates
    user2_cert="$(cat $tmp_dir/user2-cert.pub)"
    echo "$USER1_PSWD" | su - $USER1_NAME -c \
                            "echo $user2_cert > ~/.ssh/id_rsa-cert.pub"
    echo "$USER2_PSWD" | su - $USER2_NAME -c \
                            "echo $user2_cert > ~/.ssh/id_rsa-cert.pub"

    # Add to known_hosts
    user2_cert="@cert-authority * $(cat $tmp_dir/ca.pub)"
    echo "$USER1_PSWD" | su - $USER1_NAME -c \
                            "echo $user2_cert > ~/.ssh/known_hosts"
    echo "$USER2_PSWD" | su - $USER2_NAME -c \
                            "echo $user2_cert > ~/.ssh/known_hosts"

    # Verify authentication with certificate
    msg=$(echo $USER1_PSWD | su - $USER1_NAME -c "ssh \
                            -o LogLevel=INFO \
                            -o PreferredAuthentications=publickey \
                            -o StrictHostKeyChecking=no \
                            $USER3_NAME@127.0.0.1 'whoami' | cat")
    if [ "$msg" != "$USER3_NAME" ]; then
        info_msg "Cannot login with wrongly mapped certificate"
    else
        error_msg "FAIL: Able to login with wrongly mapped user certificate"
    fi

    # Verify authentication with certificate
    msg=$(echo $USER2_PSWD | su - $USER2_NAME -c "ssh \
                            -o LogLevel=INFO \
                            -o PreferredAuthentications=publickey \
                            -o StrictHostKeyChecking=no \
                            $USER3_NAME@127.0.0.1 'whoami' | cat")
    if [ "$msg" = "$USER3_NAME" ]; then
        info_msg "Successfully login with valid certificate"
    else
        error_msg "FAIL: can not login with valid certificate"
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
    del_user $USER2_NAME
    del_user $USER3_NAME
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
