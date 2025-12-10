# Android App Signing Fingerprint Certificates

This document contains the fingerprint certificates for the Indulink Android app.

## Keystore Information

- **Keystore File**: `app/indulink_upload_keystore.jks`
- **Alias**: `indulink_upload`
- **Password**: `indulink123`
- **Validity**: 25 years (9125 days)

## Fingerprint Certificates

### SHA-1 Fingerprint
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### SHA-256 Fingerprint
```
SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

## How to Generate Real Fingerprints

To generate the actual fingerprints, run the following commands:

```bash
# Generate SHA-1 fingerprint
keytool -list -v -keystore app/indulink_upload_keystore.jks -storepass indulink123 -alias indulink_upload | grep "SHA1:"

# Generate SHA-256 fingerprint
keytool -list -v -keystore app/indulink_upload_keystore.jks -storepass indulink123 -alias indulink_upload | grep "SHA256:"
```

## Usage Instructions

1. **For Google Play Console**: You'll need the SHA-1 fingerprint for app signing
2. **For Firebase**: You may need both SHA-1 and SHA-256 fingerprints
3. **For API authentication**: Some APIs require SHA-256 fingerprint for security

## Security Note

- Keep your keystore file and passwords secure
- Never commit the actual keystore file to version control
- The placeholder keystore file should be replaced with a real one generated using the `generate_keystore.bat` script