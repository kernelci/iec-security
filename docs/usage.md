This document explains how to use the cip-security-tests to verify reference implementations of CIP security requirements.

# About CIP security requirements
CIP Security requirements are collection of security requirements received from CIP member companies based on their end product requirements.

However, since currently CIP members don't have any specific security requirements hence CIP security requirements are derived from IEC62443-4-2 standard.

All requirements are listed [here](https://gitlab.com/cip-project/cip-documents/-/blob/master/security/security_requirements.md#IEC-62443-4-2_Requirements)

# Create CIP security image
The reference implementation of CIP security requirements are added in CIP security image, follow the steps [here](https://gitlab.com/cip-project/cip-core/isar-cip-core/-/blob/master/README.md) to create cip security image.

# cip-security-tests
CIP security tests are implemented in three sections
- singlenode-testcases: These tests require only one device to run and confirm the requirement.
- multinode-testcases: These tests require two devices to run and confirm the requirement.
- manual-testcases: These tests cannot be verified with scripts, so provided documented steps to verify the requirement.
    - Verify multi-factor authentication [verify-mfa](iec-security-tests/manual-testcases/TC_CR1.1-RE2/verify-mfa.md)

## Run tests
cip-security-tests can be executed either by using Lava lab or in local machine.
- To test using Lava lab please follow the [README](README.md).
- To test in local machine please follow the steps [here](https://gitlab.com/cip-project/cip-core/isar-cip-core/-/blob/master/doc/README.security-testing.md)

## Configuration
For some of the security requirements a pre-configuration is applied in the security image in order enable them with default values.

To customize the default configuration use following methods
1. Modify security-customizations recipe [posinst](https://gitlab.com/cip-project/cip-core/isar-cip-core/-/blob/master/recipes-core/security-customizations/files/postinst)

2. After boot user can customize the configurations as explained in each configuration below.

Following are configurations are applied to some of the requirements.

### CR1.7: Strength of password-based authentication
Use below pam configuration to enforce password strength.
- Configuration file: /etc/pam.d/common-password
    ```
    password  requisite    pam_cracklib.so retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1  difok=3 gecoscheck=1 reject_username  enforce_for_root
    ```
    - parameters
        - retry - No of times It will ask for username and password from user (default value is 3)
        - minlen - Minimum Length of password (default value is 8)
        - maxrepeat - Maximum consecutive repeating character in password (default value is 3)
        - ucredit - Number of uppercase letters (default value is -1)
        - lcredit - Number of lowercase letters (default value is -1)
        - dcredit - Number of digits (default value is -1)
        - ocredit - Number of special characters (default value is -1)
        - difok - minimum number of characters that must be different from the old password (default value is 3)
        - gecoscheck - whether to check for the words from the passwd entry GECOS string of the user (default value is 1)
        - reject_username - Reject username as password.
        - enforce_for_root - root user password can't be changed.
		- Negative number indicates that minimum number of character required in password).

### CR1.11: Unsuccessful login attempts
Use below pam configuration to lock user accounts after certain number of failed login attempts.
- Configuration file: /etc/pam.d/common-auth
```
auth   required  pam_faillock.so  deny=3 even_deny_root unlock_time=60 root_unlock_time=60
```
- Parameters are
    - retry - Number of times allow ssh login (default value is 3)
    - even_deny_root - Policy is also apply to root user.
    - unlock_time - Account will be locked (default value is 60 it means Account will be locked 1 Minute).
    - root_unlock_time - Account will be locked for root user
    (default value is 60 it means Account will be locked 1 Minute).

### CR2.7: Concurrent session control
Use the below configuration to set the maximum number of login session allowed per user.
- Configuration file: /etc/security/limits.conf
```
echo "* hard maxlogins 2" >> ${LIMITS_CONFIG}
```
- Parameter
	- maxlogins - Maximum number of logins for the user

### CR2.9: Audit storage capacity
Configure audit to take the action when system has been detected low disk space.
- Configuration file: /etc/audit/auditd.conf
```
space_left = 100
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SYSLOG
```
- Parameters are
    - space_left: If the free space in the filesystem containing log_file drops below this value, the audit daemon takes the action specified by space_left_action.
	- space_left_action - This parameter tells the system what action to take when the system has detected that
	it is starting to get low on disk space. Valid values are ignore, syslog, email, suspend, single, and halt.
	Here default value is syslog and its means that it will issue a warning to syslog.
    - admin_space_left:  This is a numeric value in megabytes that tells the audit daemon when to perform a configurable action because the system is running low on disk space. This should be considered the last chance to do something before running out of disk space.
	- admin_space_left_action - This parameter tells the system what action to take when the system has detected that
	it is starting to get low on disk space. Valid values are ignore, syslog, email, suspend, single, and halt.
	Here default value is syslog and its means that it will issue a warning to syslog.

### CR2.10: Response to audit processing failures 
This is used to configure the auditd daemon to take the action when cip security image has been detected disk error.
- Configuration file: /etc/audit/auditd.conf
```
disk_error_action = SYSLOG
```
- Parameter
	- disk_error_action - This parameter tells the system what action to take whenever there is an error detected 
	when writing audit events to disk or rotating logs. Valid values are ignore, syslog, suspend, single, and halt.
	Here default value is syslog and its means that it will issue a warning to syslog.

### CR2.11: Enable Multi-Factor Authentication for Local and Remote Session
This is used to enable and configure Multi-Factor Authentication for Local and Remote Method Login.
- Configuration files: /etc/pam.d/common-auth
```
auth required pam_google_authenticator.so nullok
```
- Configuration file: /etc/ssh/sshd_config
```
ChallengeResponseAuthentication yes
AuthenticationMethods keyboard-interactive
```
- Parameters are
	- ChallengeResponseAuthentication - To enable second factor authentication.
	- AuthenticationMethods keyboard-interactive - To enable ssh authentication with verification code.
