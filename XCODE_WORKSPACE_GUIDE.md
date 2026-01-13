# Xcode Workspace Configuration for T2S2T Multi-Platform Project

## Project Structure Overview

The project has a multi-platform structure with three main targets:

```
t2s2t/ (root folder)
├── T2S2T/              # iOS app source code
├── T2S2TMac/          # macOS app source code
├── T2S2TWatch/        # watchOS app source code
├── Shared/            # Shared code between platforms
├── *.md               # Project documentation files
├── T2S2T/             # Contains Xcode project files and build scripts
│   ├── T2S2T.xcodeproj/     # Xcode project (to be created)
│   ├── T2S2T.xcworkspace/   # Xcode workspace (to be created)
│   ├── setup_xcode_project.sh
│   └── build_scripts/
└── *.md               # Additional documentation in root
```

## Correct Approach: Open Root Folder in Xcode

**You should open the `t2s2t` root folder in Xcode**, not the `T2S2T` subfolder. Here's why:

1. **Multi-Platform Project**: Xcode needs to see all three targets (iOS, macOS, watchOS) to manage them as a single project
2. **Shared Resources**: The `Shared` folder contains code used by all platforms
3. **Workspace Benefits**: Using a workspace allows sharing schemes, build configurations, and dependencies

## Step-by-Step Configuration

### Option A: Create New Xcode Project (Recommended)

1. **Open Xcode** and select "Create New Project"
2. Choose **"Multiplatform App"** template
3. Configure:
   - Product Name: `T2S2T`
   - Organization Identifier: `com.yourcompany`
   - Interface: SwiftUI
   - Language: Swift
   - Include: iOS, macOS, watchOS targets
   - Use Core Data: ✅
4. Save in the **root `t2s2t` folder** (overwrite if prompted)
5. Xcode will create:
   - `T2S2T.xcodeproj` with three targets
   - Platform-specific folders with starter code

### Option B: Use Existing Structure

If you prefer to keep the existing folder structure:

1. **Open Xcode** and select "Open another project"
2. Navigate to the **`t2s2t` root folder**
3. Select **"T2S2T.xcworkspace"** if it exists, or create a new workspace:
   - File → New → Workspace
   - Save as `T2S2T.xcworkspace` in the root folder
4. Add existing projects:
   - File → "Add Files to T2S2T..."
   - Add each platform folder as needed

## Target Configuration for Each Platform

### iOS Target (`T2S2T`)
- **Source**: `T2S2T/` folder
- **Minimum Deployment**: iOS 16.0
- **Capabilities**: iCloud, Speech, Background Modes
- **Info.plist**: `T2S2T/Info.plist`

### macOS Target (`T2S2TMac`)
- **Source**: `T2S2TMac/` folder
- **Minimum Deployment**: macOS 13.0
- **Capabilities**: iCloud, Speech
- **App Sandbox**: Enabled with microphone access

### watchOS Target (`T2S2TWatch`)
- **Source**: `T2S2TWatch/` folder
- **Minimum Deployment**: watchOS 9.0
- **Capabilities**: Limited speech recognition
- **Companion App**: References iOS app for data sync

## Shared Code Organization

Place shared code in the `Shared/` folder:
- `Shared/Services/` - SpeechService, LLMService (platform-agnostic versions)
- `Shared/Models/` - Data models, Core Data stack
- `Shared/Utilities/` - Configuration, helpers

Reference shared code in each target:
1. Select target → Build Phases → Compile Sources
2. Add files from `Shared/` folder
3. Ensure they're included in all target memberships

## Build Configuration Tips

1. **Shared Schemes**:
   - Create schemes for "All Targets"
   - Enable "Shared" checkbox for team collaboration

2. **Build Settings**:
   - Set "Always Embed Swift Standard Libraries" to YES
   - Enable "Use Swift Concurrency" for all targets
   - Configure code signing for each platform

3. **Dependencies**:
   - Add frameworks per platform (Speech.framework for iOS/macOS)
   - Use Swift Package Manager for shared dependencies

## Verification Steps

After configuration:

1. **Build All Targets**: Product → Build For → Running
2. **Test on Simulators**: Run each target on appropriate simulator
3. **Verify Capabilities**: Check that speech recognition works on each platform
4. **Test Data Sync**: Create data on iOS, verify sync to macOS/watchOS

## Troubleshooting

**Issue**: "Missing source files" errors
**Solution**: Ensure file references are relative to the project root, not absolute paths

**Issue**: Capabilities not available on certain platforms
**Solution**: Some capabilities (Background Modes) are iOS-only; adjust per platform

**Issue**: Code signing errors
**Solution**: Configure separate bundle identifiers for each target:
- iOS: `com.yourcompany.T2S2T`
- macOS: `com.yourcompany.T2S2T.mac`
- watchOS: `com.yourcompany.T2S2T.watch`

## Next Steps

1. Run the automated setup script: `./T2S2T/setup_xcode_project.sh`
2. Follow platform-specific guides in each folder
3. Configure CI/CD for multi-platform builds
4. Test on physical devices for full capability validation

## Summary

**Open the root `t2s2t` folder in Xcode** to manage all three platforms as a unified project. This approach provides:
- Centralized configuration
- Shared code management
- Consistent build settings
- Efficient multi-platform development