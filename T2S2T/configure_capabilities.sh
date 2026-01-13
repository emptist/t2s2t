#!/bin/bash
# Capabilities Configuration Script for T2S2T
# This script guides through configuring necessary capabilities in Xcode

echo "T2S2T Capabilities Configuration"
echo "================================"
echo ""
echo "This application requires the following capabilities:"
echo "1. Speech Recognition"
echo "2. Microphone Access"
echo "3. iCloud with CloudKit"
echo "4. App Groups (for sharing data between app/extensions)"
echo "5. Background Modes (Audio)"
echo ""
echo "Follow these steps in Xcode:"

cat << 'EOF'

STEP 1: Open Capabilities Tab
--------------------------------
1. Select your project in the navigator
2. Select the T2S2T target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" to add each capability

STEP 2: Add iCloud Capability
--------------------------------
1. Click "+ Capability" and choose "iCloud"
2. Enable "CloudKit"
3. Click "CloudKit Console" to set up your container
4. Ensure container identifier matches: iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)
5. Add the following services:
   - CloudKit Dashboard (enable for production)
   - Key-value storage
   - iCloud Documents (optional)

STEP 3: Add App Groups
--------------------------------
1. Add "App Groups" capability
2. Click "+" to add a new group
3. Use: group.$(PRODUCT_BUNDLE_IDENTIFIER)
   Example: group.com.yourcompany.T2S2T
4. Ensure the group is enabled for your target

STEP 4: Add Background Modes
--------------------------------
1. Add "Background Modes" capability
2. Enable:
   - Audio, AirPlay, and Picture in Picture
   - Background fetch (optional)
   - Remote notifications (optional)

STEP 5: Verify Entitlements
--------------------------------
The entitlements file (T2S2T.entitlements) should contain:
- com.apple.security.app-sandbox = true
- com.apple.security.device.microphone = true
- com.apple.security.speechrecognition = true
- iCloud container identifiers
- App Groups identifiers

STEP 6: Info.plist Privacy Descriptions
----------------------------------------
Verify these keys are present in Info.plist:
- NSMicrophoneUsageDescription
- NSSpeechRecognitionUsageDescription

STEP 7: Test Capabilities
--------------------------------
1. Build and run on a physical device (some capabilities don't work on simulator)
2. Test speech recognition
3. Test iCloud sync by creating data on one device and checking another
4. Verify background audio continues when app is in background

TROUBLESHOOTING:
----------------
1. If iCloud doesn't sync:
   - Check CloudKit dashboard for container status
   - Verify iCloud is enabled in device Settings
   - Check console logs for CloudKit errors

2. If speech recognition fails:
   - Ensure device has internet (for server-side recognition)
   - Check microphone permissions in Settings
   - Verify language is supported

3. If background audio stops:
   - Ensure audio session is configured properly
   - Check Background Modes are enabled
   - Verify audio continues in other apps

EOF

echo ""
echo "For detailed implementation, see the SpeechService.swift and DataController.swift files."
echo ""
echo "Configuration complete!"