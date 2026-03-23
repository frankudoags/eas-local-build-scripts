#!/bin/bash

# Get the list of available AVDs
avd_list=$(emulator -list-avds)

# Check if Test_Android exists in the list
if echo "$avd_list" | grep -q "Test_Android"; then
    echo "Starting Test_Android emulator..."
    emulator -avd Test_Android
else
    echo "Error: Test_Android AVD not found in the list of available AVDs."
    echo "Available AVDs:"
    echo "$avd_list"
    echo ""
    echo "To create the Test_Android AVD, follow these steps:"
    echo "1. Open Android Studio"
    echo "2. Go to Tools > Device Manager"
    echo "3. Click on 'Create Device' button"
    echo "4. Select a phone device (e.g. Pixel 4)"
    echo "5. Choose a system image (recommended: API 33/Android 13)"
    echo "6. In AVD Name field, enter 'Test_Android'"
    echo "7. Click Finish"
    echo ""
    echo "Or use the command line:"
    echo "sdkmanager \"system-images;android-33;google_apis;x86_64\""
    echo "avdmanager create avd -n Test_Android -k \"system-images;android-33;google_apis;x86_64\" -d \"pixel_4\""
    exit 1
fi