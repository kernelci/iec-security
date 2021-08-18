#!/bin/bash
# TC_CR1.7_1: Validate Strength of password-based authentication
#
set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.7_1: Validate Strength of password-based authentication"

PAM_FILE="/etc/pam.d/common-password"
pam_cracklib_config="password  requisite    pam_cracklib.so \
    retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 \
    dcredit=-1 ocredit=-1 difok=3 gecoscheck=1 reject_username \
    enforce_for_root"

preTest() {
    check_root
    check_pkgs_installed "libpam-cracklib" "libpam-runtime" "passwd"

    # Create the users for the test case
    create_test_user $USER1_NAME $USER1_PSWD

    # If pam_craclib already configured, comment that temporarily
    sed -i '/pam_cracklib.so/ s/^/#/' $PAM_FILE

    # configure pam to  enforce password strength
    sed -i "0,/^password.*/s/^password.*/${pam_cracklib_config}\n&/" ${PAM_FILE}
}

runTest() {
    strong_pwd="Hello@4567"
    weak_pwd="test"

    cmd_msg=$(echo "$USER1_NAME:$weak_pwd" | sudo chpasswd 2>&1 | cat)
    if echo $cmd_msg | grep -q "BAD PASSWORD: it is too short"; then
        info_msg "Password change is not accepting week password"
    else
        error_msg "FAIL: Accepting week passwords"
    fi

    cmd_msg=$(echo "$USER1_NAME:$strong_pwd" | sudo chpasswd 2>&1 | cat)
    if [ "" = "$cmd_msg" ];then
        info_msg "Password is changed with strong password"
    else
        error_msg "FAIL: Cannot change password"
    fi

    info_msg "PASS"
}

postTest() {
    # remove the configuration line that was set
    sed -i "/$pam_cracklib_config/d" ${PAM_FILE}

    # uncomment the pam_cracklib that was commented earlier
    sed -i '/pam_cracklib.so/ s/^#//' $PAM_FILE

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
