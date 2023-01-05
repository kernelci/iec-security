#!/bin/bash
# Security Test case
# TC_CR7.3_2: Control system backup to remote machine
# This testcase demonistrate the remote backup & restore functionality,
# /etc is taken as a backup after creating a sample file in it
# It is deleted intentionally in the local file system
# so that it can be restored from the backup taken.

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR7.3: Control system backup"
BACKUP_DIR="/etc"
BACKUP_LOC="backup_storage"
export PASSPHRASE
export FTP_PASSWORD=$USER1_PSWD

preTest() {
    check_root
    check_pkgs_installed "duplicity" "python3-paramiko"
    create_test_user $USER1_NAME $USER1_PSWD
    touch ${BACKUP_DIR}/sample_file
}

runTest() {

    # Verify the remote session cab establish
    msg=$(sshpass -p $USER1_PSWD ssh -o StrictHostKeyChecking=no $USER1_NAME@127.0.0.1 "whoami" | cat)
    if [ "$msg" = "$USER1_NAME" ]; then
        info_msg "User can access the remote session"
    else
        error_msg "FAIL: User can not access the remote session"
    fi

    # Take the backup of /etc folder
    duplicity --ssh-askpass ${BACKUP_DIR} scp://${USER1_NAME}@127.0.0.1:/${BACKUP_LOC}

    # Check the presence of sample file in the backup and then delete it
    duplicity --ssh-askpass list-current-files scp://${USER1_NAME}@127.0.0.1:/${BACKUP_LOC} > backup.log 2>&1 || echo
    if grep -q "sample_file" backup.log; then
        rm -f /etc/sample_file
        info_msg "Delete file /etc/sample_file which is already backed up"
    else
        error_msg "/etc/sample_file not backed up"
    fi

    # Restore the lost file in its original location and check it's presence
    duplicity --ssh-askpass --file-to-restore sample_file scp://${USER1_NAME}@127.0.0.1:/${BACKUP_LOC} ${BACKUP_DIR}/sample_file
    if [ -f ${BACKUP_DIR}/sample_file ]; then
        info_msg "The sample file is successfully restored"
    else
        error_msg "Restore failed"
    fi
    info_msg "PASS"
}

postTest() {

     #Delete the backup
     [ -f backup.log ] && rm -f backup.log
     rm -rf ${BACKUP_LOC}
     info_msg "Cleaned the backup storage"
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
