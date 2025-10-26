# Android Signing Configuration

This directory contains the Android signing configuration for the Finance Tracker app.

## Files

- `key.properties` - Contains keystore passwords and configuration (not committed to version control)
- `app/upload-keystore.jks` - The signing keystore (not committed to version control)
- `app/build.gradle.kts` - Updated with signing configuration

## Setup

### 1. Key Properties Configuration

Edit the `key.properties` file with your actual keystore passwords:

```properties
# Android keystore properties
storePassword=your_actual_keystore_password
keyPassword=your_actual_key_password
keyAlias=finance_key
storeFile=upload-keystore.jks
```

### 2. Build the App

To build a release APK with signing:

```bash
flutter build apk --release
```

To build an app bundle (recommended):

```bash
flutter build appbundle --release
```

## Security Notes

- Never commit the `key.properties` file or keystore (`.jks`) files to version control
- Keep your keystore passwords secure
- The keystore has a validity of 10,000 days (~27 years)
- Use environment variables for CI/CD deployments

## CI/CD Deployment

For automated builds, set these environment variables instead of using `key.properties`:

- `KEYSTORE_PASSWORD` - Your keystore password
- `KEY_PASSWORD` - Your key password

The build configuration will automatically use these environment variables if the `key.properties` file is not found.
