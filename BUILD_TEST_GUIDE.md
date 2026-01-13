# Build Test Guide for T2S2T

This guide provides instructions for testing the build process of the T2S2T project after configuration.

## Prerequisites

- macOS with Xcode 15+ installed
- Command Line Tools installed (`xcode-select --install`)
- XcodeGen installed (`brew install xcodegen`)
- iOS Simulator (for iOS testing)
- Physical device (optional, for full capability testing)

## Step 1: Generate Xcode Project

First, generate the Xcode project using XcodeGen:

```bash
cd /Users/jk/gits/hub/two_way_com_training/t2s2t
./setup_xcode_project.sh
```

Or manually:
```bash
xcodegen generate
```

Verify `T2S2T.xcodeproj` was created:
```bash
ls -la T2S2T.xcodeproj/
```

## Step 2: Validate Project Structure

Verify the project structure manually:

```bash
required_files=(
  "T2S2T/App/T2S2TApp.swift"
  "T2S2T/Info.plist"
  "T2S2T/T2S2T.entitlements"
  "T2S2TMac/T2S2TMac.entitlements"
  "Shared/Models/DataController.swift"
  "Shared/Services/SpeechService.swift"
  "Shared/Services/LLMService.swift"
  "Shared/Utilities/Configuration.swift"
  "T2S2T/Views/ConversationView.swift"
  "Shared/Models/T2S2T.xcdatamodeld/contents"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ $file"
  else
    echo "✗ Missing: $file"
  fi
done
```

## Step 3: Build Test Commands

### Test iOS Build:
```bash
xcodebuild -project T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  clean build
```

### Test macOS Build:
```bash
xcodebuild -project T2S2T.xcodeproj \
  -scheme T2S2TMac \
  -destination 'platform=macOS' \
  clean build
```

### Test watchOS Build:
```bash
xcodebuild -project T2S2T.xcodeproj \
  -scheme T2S2TWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 9' \
  clean build
```

## Step 4: Run Tests

### Unit Tests:
```bash
xcodebuild -project T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test
```

### UI Tests (if configured):
```bash
xcodebuild -project T2S2T.xcodeproj \
  -scheme T2S2T \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test -only-testing:T2S2TUITests
```

## Step 5: Manual Testing Checklist

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

## Step 6: Troubleshooting Common Build Issues

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
3. Regenerate project: `xcodegen generate`

### Issue: "Missing entitlements"
**Solution**: Verify entitlements file is configured:
1. Select target → Signing & Capabilities
2. Ensure entitlements file is listed
3. All required capabilities are enabled

### Issue: "XcodeGen not found"
**Solution**: Install XcodeGen:
```bash
brew install xcodegen
```

## Step 7: Performance Testing

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

## Step 8: Continuous Integration

Sample GitHub Actions workflow (`.github/workflows/ci.yml`):

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install XcodeGen
        run: brew install xcodegen
      - name: Generate Xcode project
        run: xcodegen generate
      - name: Build iOS
        run: xcodebuild -project T2S2T.xcodeproj -scheme T2S2T -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
      - name: Build macOS
        run: xcodebuild -project T2S2T.xcodeproj -scheme T2S2TMac -destination 'platform=macOS' build
      - name: Run Tests
        run: xcodebuild -project T2S2T.xcodeproj -scheme T2S2T -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

## Step 9: Final Verification

Before releasing:

- [ ] All build configurations pass
- [ ] Unit tests pass (≥ 80% coverage)
- [ ] UI tests pass
- [ ] No warnings in build log
- [ ] App Store Connect validation passes
- [ ] TestFlight distribution works
- [ ] All platform-specific features validated

## Support Resources

- `QUICK_START.md` - Quick setup guide
- `PROJECT_SUMMARY.md` - Project overview and architecture
- `README.md` - General project setup
- `setup_xcode_project.sh` - Project generation script

For issues, check Xcode console logs or run:
```bash
xcodebuild -project T2S2T.xcodeproj -scheme T2S2T -showBuildTimingSummary