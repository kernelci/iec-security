# cip-security-tests

This repository contains the tests that should validate the security requirements defined for cyber security standard such as IEC-62443-4-2.

## iec-security-tests
This folder contains the tests for IEC-62443-4-2 standard.

To run tests in the CIP LAVA:

1. Login to https://lava.ciplatform.org
2. Scheduler -> Submit
3. Copy and paste your definition into the submit job window, validate and submit

e.g. Lava Definition for test block
```
# TEST_BLOCK
- test:
    timeout:
      minutes: 20
    definitions:
    - repository: https://gitlab.com/cip-playground/cip-security-tests.git
      from: git
      branch: master
      path: iec-security-tests/Singlenode-TestDefinition.yaml
      name: IEC_Security_Tests
```
