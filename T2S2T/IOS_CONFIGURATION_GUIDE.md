# iOS Target Configuration Guide for T2S2T

This guide provides step-by-step instructions for configuring the iOS target after opening the T2S2T project in Xcode.

## **IMPORTANT CORRECTION: Folder to Open**

The project has a multi-platform structure:
```
t2s2t/ (root folder)
├── T2S2T/          # iOS app source code
├── T2S2TMac/      # macOS app source code
├── T2S2TWatch/    # watchOS app source code
├── Shared/        # Shared code
└── T2S2T.xcodeproj/ # Xcode project
```

**You should open the ROOT `t2s2t` folder in Xcode**, not the `T2S2T` subfolder. This allows Xcode to manage all three platforms as a unified project.

## Prerequisites

- macOS with Xcode 15+
- Apple Developer Account (for signing and capabilities)
- Physical iOS device (optional but recommended for testing capabilities)

## Step 1: Open Project in Xcode

1. Launch Xcode
2. Select "Open a project or file"
3. Navigate to the **`t2s2t` root folder** (the one containing T2S2T, T2S2TMac, T2S2TWatch subfolders)
4. Select `T2S2T.xcodeproj` or `T2S2T.xcworkspace` if they exist

**If project file doesn't exist:** Create a new Xcode project:
- File → New → Project
- Select **"Multiplatform App"** template (to get iOS, macOS, watchOS targets)
- Product Name: `T2S2T`
- Interface: SwiftUI
- Language: Swift
- Use Core Data: ✅
- Include Tests: ✅
- Save in the **root `t2s2t` folder** (not the T2S2T subfolder)

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
3. Add capabilities (click "+ Capability"):

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

   ### Privacy Permissions (auto-added via Info.plist):
   - Microphone Usage
   - Speech Recognition Usage

## Step 4: Configure Info.plist

The project includes a pre-configured `Info.plist` in `T2S2T/Info.plist` with:

- `NSMicrophoneUsageDescription`: "T2S2T needs microphone access for voice conversations"
- `NSSpeechRecognitionUsageDescription`: "T2S2T uses speech recognition to understand your language practice"
- App Transport Security exceptions for OpenAI and Anthropic APIs

Verify these entries are present in your target's Info.plist:
1. Select the project
2. Go to Build Settings
3. Search for "Info.plist File"
4. Ensure it points to `T2S2T/Info.plist`

## Step 5: Configure Build Settings

Important build settings to verify:

1. Search for "Swift Language Version" - set to Swift 6
2. Search for "Enable Modules" - set to YES
3. Search for "Always Embed Swift Standard Libraries" - set to YES
4. For Core Data with CloudKit:
   - Search for "Enable CloudKit" - set to YES
   - Search for "Use Swift Concurrency" - set to YES

## Step 6: Add Frameworks

Required frameworks:
1. Select the target
2. Go to "Build Phases"
3. Expand "Link Binary With Libraries"
4. Click "+" and add:
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

To use the pre-existing model:
1. Ensure the `Shared/Models/T2S2T.xcdatamodeld` file is referenced in Xcode
2. It should be added to all targets (iOS, macOS, watchOS)
3. Update `DataController.swift` if needed (already configured)

## Step 8: Configure Scheme

1. Product → Scheme → Edit Scheme...
2. Select "Run" on left
3. Options tab:
   - Enable "Allow Location Simulation"
   - Enable "Allow GPU Frame Capture"
4. Arguments tab:
   - Add environment variables:
     - `API_KEY_OPENAI`: (your OpenAI API key)
     - `API_KEY_ANTHROPIC`: (your Anthropic API key) - optional
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

The project includes several helper scripts:

- `T2S2T/setup_xcode_project.sh`: Interactive guide for Xcode configuration
- `T2S2T/configure_capabilities.sh`: Detailed capabilities setup
- `T2S2T/build_scripts/build.sh`: Build automation script

Run from terminal:
```bash
cd t2s2t  # Root folder
chmod +x T2S2T/setup_xcode_project.sh
./T2S2T/setup_xcode_project.sh
```

## Next Steps

After successful configuration:

1. Set up API keys in Configuration.swift
2. Test speech recognition functionality
3. Implement pedagogical feedback system
4. Add progress tracking views
5. Prepare for App Store submission

## Support

For issues, refer to:
- `XCODE_WORKSPACE_GUIDE.md` - Multi-platform workspace setup
- `PROJECT_SUMMARY.md` - Project overview
- `README.md` - General project setup