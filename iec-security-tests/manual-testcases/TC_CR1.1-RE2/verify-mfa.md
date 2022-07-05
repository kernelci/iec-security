# Verify multi-factor authentication in Linux machine
This document explains how to verify multi-factor authentication in Linux machine with local and remote login methods, it uses [google-authenticator](https://support.google.com/accounts/answer/1066447) as second factor authentication and default username-password as first factor authentication.

## Prerequisites
- The following packages should be installed in the Linux image
    - libpam-google-authenticator
    - ssh
- Add test user in Linux image
    - $ adduser test

- Install following application in android device for generating TOTP(Time based OTP).
    - [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)

## Configure PAM to enable multi-factor authentication in Linux machine
- Add following line to the end of the file `/etc/pam.d/common-auth` in order to enable multi-factor authentication in logins.
    ```
    auth required pam_google_authenticator.so nullok
    ```
- Do the following configuration in the sshd `/etc/ssh/sshd_config` to enable multi-factor authentication for remote login.
    ```
    ChallengeResponseAuthentication yes         <- Change if it is 'no'
    AuthenticationMethods keyboard-interactive  <- add this line at the end of the file
    ```
Note: If you are using isar-cip-core security image then these prerequisites and configurations are already applied, use this [README](https://gitlab.com/cip-project/cip-core/isar-cip-core/-/blob/master/README.md) to build the isar-cip-core security image.

## Generate registration code in Linux machine
Run the `google-authenticator` application in Linux machine in order to generate registration code, and that will be used in the second device(Android device) to register the Linux user account for generating One-Time code for logins.
```
$ google-authenticator
    Do you want authentication tokens to be time-based (y/n) select "y"

     [QR CODE]

    Your new secret key is: <<Secret_Key>>
    Enter code from app (-1 to skip): -1
    xxxxxxxx
    xxxxxxxx
    xxxxxxxx
    xxxxxxxx
    xxxxxxxx
    google_authenticator file.... select "y"
    disallowing multiple uses.... select "y"
    increasing the time-window... select "y"
    enable rate-limiting......... select "y"
 ```
- In the above command enter -1 for the option "Enter code from app", if you don't want to use QR code to register with Google Authenticator app in mobile device.
- Note down the secret key generated in the above command and use it while registering with Google Authenticator App in mobile device.

## Register the Linux user account in Google Authenticator mobile app
Install the Google Authenticator application as mentioned in the [prerequisites](#prerequisites)
- Open Google Authenticator App in android device
- Add device by pressing '+' button
- Select 'Enter a setup key'
    - Enter Account Name: << Linux machine user name or any name>>
    - Enter Secret Key: << Secret_Key >> <- Enter the code generated in the previous step
    - Type of key: Time based
    - Click Add button

Now the Linux user account is registered with third party application to generated one time code(OTP).

## Verify multi-factor authentication with local login
Boot the Linux image where multi-factor authentication is enabled, in the login console confirm whether it is asking for two times authentications.
```
demo login: test
Password:            <- Enter password set for test user
Verification code:   <- Enter OTP code generated in Google authenticator app
```
If it's not asking user to authenticate two times, this test should be considered as failed.

## Verify multi-factor authentication with remote login
Boot the Linux image where multi-factor authentication is enabled, and from remote machine try to ssh to this machine and confirm whether it is asking for two times authentications.
```
host$ ssh -p 22222 test@127.0.0.1
Password:            <- Enter password set for test user
Verification code:   <- Enter OTP code generated in Google authenticator app
```
If it's not asking user to authenticate two times, this test should be considered as failed.
