set -e
#!/bin/sh
# TC_CR1.3_2: Validate Accounts modification
#
set -e

. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.3_2: Validate Accounts modification"

NEW_USER="test1_3_2"

preTest() {
    check_root
    check_pkgs_installed "passwd" "login"

    # Create the users required for the test
    create_test_user $USER1_NAME $USER1_PSWD
}

runTest() {
    # Change username
    if usermod -l ${NEW_USER} ${USER1_NAME}; then
        # Login and get the username to check username modification
        user_whoami=$(echo "${USER1PSWD}" | su - "${NEW_USER}" -c "whoami")
        if [ $user_whoami = $NEW_USER ];then
            info_msg "PASS"
        else
            error_msg "FAIL: Cannot login to changed user account"
        fi       
    else
        error_msg "FAIL: Cannot change user account details"
    fi
}

postTest() {
    # delete all the users created in the test
    del_user $NEW_USER
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