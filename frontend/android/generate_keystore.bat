@echo off
cd /d %~dp0\app

echo Generating new keystore...
keytool -genkeypair -alias indulink_upload -keyalg RSA -keysize 2048 -validity 9125 -keystore indulink_upload_keystore.jks -storepass indulink123 -keypass indulink123 -dname "CN=Indulink, OU=Mobile, O=Indulink, L=Kathmandu, ST=Bagmati, C=NP"

echo.
echo Generating SHA-1 fingerprint...
keytool -list -v -keystore indulink_upload_keystore.jks -storepass indulink123 -alias indulink_upload | findstr "SHA1:"

echo.
echo Generating SHA-256 fingerprint...
keytool -list -v -keystore indulink_upload_keystore.jks -storepass indulink123 -alias indulink_upload | findstr "SHA256:"

echo.
echo Keystore generation complete!