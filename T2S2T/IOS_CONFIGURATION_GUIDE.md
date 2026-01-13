# iOS Target Configuration Guide for T2S2T

This guide provides step-by-step instructions for configuring the iOS target after generating the Xcode project.

## Quick Start

1. **Generate the Xcode project**:
   ```bash
   cd /Users/jk/gits/hub/two_way_com_training/t2s2t
   ./setup_xcode_project.sh
   ```

2. **Open the project in Xcode**:
   ```bash
   open T2S2T.xcodeproj
   ```

3. **Configure the iOS target** (steps below)

## Prerequisites

- macOS with Xcode 15+
- Apple Developer Account (for signing and capabilities)
- Physical iOS device (optional but recommended for testing capabilities)
- XcodeGen installed (handled by setup script)

## Project Structure

```
t2s2t/ (root folder)
├── project.yml              # XcodeGen configuration
├── setup_xcode_project.sh   # Project generation script
├── T2S2T.xcodeproj/         # Generated Xcode project
├── T2S2T/                   # iOS app source
│   ├── App/
│   ├── Views/
│   ├── Info.plist
│   └── T2S2T.entitlements
└── Shared/                  # Shared code
    ├── Models/
    ├── Services/
    └── Utilities/
```

## Step 1: Open Project in Xcode

1. Launch Xcode
2. Select "Open a project or file"
3. Navigate to the `t2s2t` root folder
4. Select `T2S2T.xcodeproj`

## Step 2: Configure iOS Target Settings

1. In the project navigator, select the project
2. Select **"T2S2T"** under Targets (this is the iOS target)
3. In the General tab:
   - **Display Name**: T2S2T
   - **Bundle Identifier**: `com.yourcompany.T2S2T`
   - **Version**: 1.0
   - **Build**: 1
   - **Team**: Select your Apple Developer Team
   - **Minimum Deployments**:
     - iOS: 16.0
     - iPadOS: 16.0

## Step 3: Configure Signing & Capabilities

1. Go to "Signing & Capabilities" tab
2. Enable "Automatically manage signing"
3. Click "+ Capability" and add:

### Required Capabilities:
- **iCloud**:
  - Enable CloudKit
  - Container: `iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)`
  - Services: CloudKit, Key-value storage
- **App Groups**:
  - Add group: `group.$(PRODUCT_BUNDLE_IDENTIFIER)`
- **Background Modes**:
  - Audio, AirPlay, and Picture in Picture
  - Background fetch (optional)
- **Push Notifications** (optional)

### Privacy Permissions (in Info.plist):
- Microphone Usage
- Speech Recognition Usage

These are pre-configured in `T2S2T/Info.plist`.

## Step 4: Configure Info.plist

The project includes a pre-configured `Info.plist` in `T2S2T/Info.plist` with:

- `NSMicrophoneUsageDescription`: "T2S2T needs microphone access for voice conversations"
- `NSSpeechRecognitionUsageDescription`: "T2S2T uses speech recognition to understand your language practice"
- App Transport Security exceptions for OpenAI and Anthropic APIs

## Step 5: Configure Build Settings

Important build settings to verify:

1. Search for "Swift Language Version" - set to Swift 5.9
2. Search for "Enable Modules" - set to YES
3. Search for "Always Embed Swift Standard Libraries" - set to YES
4. For Core Data with CloudKit:
   - Search for "Enable CloudKit" - set to YES
   - Search for "Use Swift Concurrency" - set to YES

## Step 6: Add Frameworks

Required frameworks are automatically linked via XcodeGen, but verify:
1. Select the target
2. Go to "Build Phases"
3. Expand "Link Binary With Libraries"
4. Verify these are present:
   - `AVFoundation.framework`
   - `Speech.framework`
   - `CoreData.framework`
   - `CloudKit.framework`
   - `Combine.framework`
   - `SwiftUI.framework`
   - `Foundation.framework`

## Step 7: Core Data Model

The project includes a Core Data model (`Shared/Models/T2S2T.xcdatamodeld/`) with three entities:

- **UserProfile**: User information and preferences
- **Conversation**: Recorded conversation sessions
- **ProgressEntry**: Daily progress tracking

To verify:
1. Ensure `T2S2T.xcdatamodeld` is in the project navigator
2. Check target membership includes T2S2T
3. It's in "Copy Bundle Resources" build phase

## Step 8: Configure Scheme

1. Product → Scheme → Edit Scheme...
2. Select "Run" on left
3. Options tab:
   - Enable "Allow Location Simulation"
   - Enable "Allow GPU Frame Capture"
4. Arguments tab:
   - Add environment variables:
     - `OPENAI_API_KEY`: (your OpenAI API key)
     - `ANTHROPIC_API_KEY`: (optional)
5. Diagnostics tab:
   - Enable "Main Thread Checker"
   - Enable "Runtime API Checking"

## Step 9: Test Build

1. Select a simulator (iPhone 15 Pro)
2. Product → Build (Cmd+B)
3. Check for any build errors
4. Product → Run (Cmd+R) to run in simulator

## Step 10: Configure Other Platforms (Optional)

For macOS and watchOS targets:
1. Select `T2S2TMac` target for macOS configuration
2. Select `T2S2TWatch` target for watchOS configuration
3. Repeat similar steps for each platform (adjust capabilities as needed)

## Troubleshooting

### Common Issues:

1. **iCloud not syncing**:
   - Check CloudKit dashboard for container status
   - Verify iCloud is enabled in device Settings
   - Check console logs for CloudKit errors

2. **Speech recognition fails**:
   - Ensure device has internet (for server-side recognition)
   - Check microphone permissions in Settings
   - Verify language is supported

3. **Background audio stops**:
   - Ensure audio session is configured properly
   - Check Background Modes are enabled
   - Verify audio continues in other apps

4. **Core Data migration issues**:
   - Delete app and reinstall
   - Check lightweight migration options

## Automated Scripts

The project includes helper scripts:

- `setup_xcode_project.sh`: Generates Xcode project with XcodeGen
- `T2S2T/build_scripts/build.sh`: Build automation script

Run from terminal:
```bash
cd t2s2t  # Root folder
./setup_xcode_project.sh  # Generate project
./T2S2T/build_scripts/build.sh build  # Build project
```

## Next Steps

After successful configuration:

1. Set up API keys in environment or Configuration.swift
2. Test speech recognition functionality
3. Implement pedagogical feedback system
4. Add progress tracking views
5. Prepare for App Store submission

## Support

For issues, refer to:
- `XCODE_WORKSPACE_GUIDE.md` - Multi-platform workspace setup
- `PROJECT_SUMMARY.md` - Project overview
- `QUICK_START.md` - Quick setup guide
- `README.md` - General project setup