#!/bin/bash
# TC_CR1.9_6: Strength of public key-based authentication
#  - use of cryptography

set -e
. ../../lib/common-lib
. ../../lib/common-variables

TEST_CASE_NAME="TC_CR1.9_6: Strength of public key-based authentication \
- use of cryptography"

preTest() {
    echo ""
}

runTest() {
    supported_alg=$(sshd -T | awk '/^pubkeyacceptedkeytypes/' | awk '{print $2}' | sed 's/,/ /g')
    echo "Suuported algorithems: $supported_alg"
}

postTest() {
    echo ""
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