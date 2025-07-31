#!/bin/bash

# Exit on any error
set -e

# Replace with your actual package name (check app/build.gradle)
PACKAGE_NAME="edu.emory.audio_diaries_flutter"

# Grant required permissions via ADB
adb shell pm grant "$PACKAGE_NAME" android.permission.RECORD_AUDIO
adb shell pm grant "$PACKAGE_NAME" android.permission.CAMERA
adb shell pm grant "$PACKAGE_NAME" android.permission.POST_NOTIFICATIONS
adb shell pm grant "$PACKAGE_NAME" android.permission.ACCESS_FINE_LOCATION

echo "Permissions granted for $PACKAGE_NAME"