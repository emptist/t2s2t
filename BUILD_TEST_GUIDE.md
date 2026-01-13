# Build Test Guide for T2S2T

This guide provides instructions for testing the build process of the T2S2T project after configuration.

## Prerequisites

- macOS with Xcode 15+ installed
- Command Line Tools installed (`xcode-select --install`)
- iOS Simulator (for iOS testing)
- Physical device (optional, for full capability testing)

## Step 1: Validate Project Structure

Verify the project structure manually:

```bash
# Check for essential files
required_files=(
  "T2S2T/App/T2S2TApp.swift"
  "T2S2T/Info.plist"
  "T2S2T/T2S2T.entitlements"
  "Shared/Models/DataController.swift"
  "Shared/Services/SpeechService.swift"
  "Shared/Services/LLMService.swift"
  "Shared/Utilities/Configuration.swift"
  "T2S2T/Views/ConversationView.swift"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ $file"
  else
    echo "✗ Missing: $file"
  fi
done
```

## Step 2: Create Xcode Project

If you haven't created the Xcode project yet:

1. **Open Xcode** and select "Create New Project"
2. Choose **"Multiplatform App"** template
3. Configure:
   - Product Name: `T2S2T`
   - Organization Identifier: `com.yourcompany`
   - Interface: SwiftUI
   - Language: Swift
   - Include: iOS, macOS, watchOS targets
   - Use Core Data: ✅
   - Include Tests: ✅
4. Save in the **root `t2s2t` folder** (overwrite if prompted)
5. **Add existing files** to the project:
   - Drag the `T2S2T`, `T2S2TMac`, `T2S2TWatch`, and `Shared` folders into Xcode
   - Ensure "Copy items if needed" is **unchecked**
   - Create groups for each folder
   - Add files to appropriate targets (iOS files to iOS target, etc.)

## Step 3: Configure Build Settings

Verify these build settings for each target:

### iOS Target (`T2S2T`):
- **Deployment Target**: iOS 16.0
- **Frameworks**: AVFoundation, Speech, CoreData, CloudKit, Combine
- **Capabilities**: iCloud, App Groups, Background Modes (Audio)
- **Info.plist**: Ensure microphone and speech recognition usage descriptions

### macOS Target (`T2S2TMac`):
- **Deployment Target**: macOS 13.0
- **Frameworks**: AVFoundation, Speech (if available), CoreData, CloudKit
- **App Sandbox**: Enabled with microphone access

### watchOS Target (`T2S2TWatch`):
- **Deployment Target**: watchOS 9.0
- **Frameworks**: CoreData (limited), WatchKit

## Step 4: Build Test Commands

### Test iOS Build:
```bash
cd /Users/jk/gits/hub/two_way_com_training/t2s2t
xcodebuild -project T2S2T/T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  clean build
```

### Test macOS Build:
```bash
xcodebuild -project T2S2T/T2S2T.xcodeproj \
  -scheme T2S2TMac \
  -destination 'platform=macOS' \
  clean build
```

### Test watchOS Build:
```bash
xcodebuild -project T2S2T/T2S2T.xcodeproj \
  -scheme T2S2TWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9' \
  clean build
```

## Step 5: Run Tests

### Unit Tests:
```bash
xcodebuild -project T2S2T/T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test
```

### UI Tests (if configured):
```bash
xcodebuild -project T2S2T/T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test -only-testing:T2S2TUITests
```

## Step 6: Manual Testing Checklist

### Core Functionality:
- [ ] App launches without crashes
- [ ] Speech recognition authorization prompt appears
- [ ] Microphone permission request works
- [ ] Core Data stack initializes
- [ ] Conversation view loads
- [ ] Language picker functions
- [ ] Recording starts/stops
- [ ] Speech synthesis works (AI responses)

### Platform-Specific:
#### iOS:
- [ ] Background audio continues when app is in background
- [ ] iCloud sync works across devices
- [ ] App Groups for sharing data with extensions

#### macOS:
- [ ] App runs in windowed mode
- [ ] Menu bar functions
- [ ] Sandbox permissions work

#### watchOS:
- [ ] App launches on watch simulator
- [ ] Complications work (if implemented)
- [ ] Handoff to iOS app

## Step 7: Troubleshooting Common Build Issues

### Issue: "Missing required module 'Speech'"
**Solution**: Ensure Speech.framework is linked to the target:
1. Select target → Build Phases → Link Binary With Libraries
2. Click "+" and add Speech.framework

### Issue: "Code signing errors"
**Solution**: Configure automatic signing or manual certificates:
1. Select target → Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your team

### Issue: "Core Data model not found"
**Solution**: Ensure the model is in the target bundle:
1. Select `T2S2T.xcdatamodeld` in Xcode
2. Check target membership in the File Inspector (right sidebar)

### Issue: "Missing entitlements"
**Solution**: Verify entitlements file is configured:
1. Select target → Signing & Capabilities
2. Ensure `T2S2T.entitlements` is listed
3. All required capabilities are enabled

## Step 8: Performance Testing

### Memory Usage:
1. Run app in Instruments (Allocations)
2. Check for memory leaks during conversation
3. Monitor Core Data faulting behavior

### Battery Impact:
1. Test background audio recording impact
2. Monitor network usage during LLM API calls
3. Optimize speech recognition intervals

### Storage:
1. Verify Core Data stores correctly
2. Test iCloud sync performance
3. Monitor local storage growth

## Step 9: Continuous Integration

Sample GitHub Actions workflow (`.github/workflows/ci.yml`):

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build iOS
        run: xcodebuild -project T2S2T/T2S2T.xcodeproj -scheme T2S2T -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
      - name: Build macOS
        run: xcodebuild -project T2S2T/T2S2T.xcodeproj -scheme T2S2TMac -destination 'platform=macOS' build
      - name: Run Tests
        run: xcodebuild -project T2S2T/T2S2T.xcodeproj -scheme T2S2T -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

## Step 10: Final Verification

Before releasing:

- [ ] All build configurations pass
- [ ] Unit tests pass (≥ 80% coverage)
- [ ] UI tests pass
- [ ] No warnings in build log
- [ ] App Store Connect validation passes
- [ ] TestFlight distribution works
- [ ] All platform-specific features validated

## Support Resources

- `IOS_CONFIGURATION_GUIDE.md` - iOS-specific configuration
- `XCODE_WORKSPACE_GUIDE.md` - Multi-platform workspace setup
- `PROJECT_SUMMARY.md` - Project overview and architecture
- `README.md` - General project setup

For issues, check Xcode console logs or run:
```bash
xcodebuild -project T2S2T/T2S2T.xcodeproj -scheme T2S2T -showBuildTimingSummary