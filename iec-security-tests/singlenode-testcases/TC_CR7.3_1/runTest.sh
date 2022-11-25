#!/bin/bash
# Security Test case
# TC_CR7.3: Control system backup
# Goal of the TC is to demo the local backup & restore functionality
# /etc is taken as a backup after creating a sample file in it
# It is deleted intentionally in the local file system
# so that it can be restored from the backup taken.
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR7.3: Control system backup"
BACKUP_DIR="/etc"
BACKUP_LOC="/usr/local/backup"
export PASSPHRASE
preTest() {
    check_root
    check_pkgs_installed "duplicity"

    # Create a backup storage location
    mkdir -p ${BACKUP_LOC}
    touch ${BACKUP_DIR}/sample_file
}

runTest() {

    #Take the backup of a folder and then delete it.
    duplicity ${BACKUP_DIR} file://${BACKUP_LOC}

    # Check if the deleted directory is present in the backup
    duplicity list-current-files file://${BACKUP_LOC} > backup.log 2>&1 || echo
    if grep -q "sample_file" backup.log; then
        rm -f /etc/sample_file
        info_msg "Delete file /etc/sample_file which is already backed up"
    else
        error_msg "Delete file /etc/sample_file which is already backed up"
    fi

    # Restore the lost file in its original location and check it's presence
    duplicity --file-to-restore sample_file file://${BACKUP_LOC} ${BACKUP_DIR}/sample_file
    if [ -f ${BACKUP_DIR}/sample_file ]; then
        info_msg "The package is successfully restored"
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
