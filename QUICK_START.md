# T2S2T Quick Start Guide

## Open and Run in Xcode - Step by Step

### Step 1: Generate the Xcode Project

1. **Navigate to the project root folder**:
   ```bash
   cd /Users/jk/gits/hub/two_way_com_training/t2s2t
   ```

2. **Run the setup script**:
   ```bash
   chmod +x setup_xcode_project.sh
   ./setup_xcode_project.sh
   ```

   This will:
   - Check for XcodeGen installation
   - Install XcodeGen if not present
   - Generate `T2S2T.xcodeproj`
   - Verify required files are present

3. **Alternative: Manual project generation**:
   ```bash
   brew install xcodegen  # If not installed
   xcodegen generate
   ```

### Step 2: Open the Project in Xcode

1. **Open Xcode**
2. Click "Open a project or file"
3. Navigate to: `/Users/jk/gits/hub/two_way_com_training/t2s2t`
4. Select `T2S2T.xcodeproj`

### Step 3: Configure Target Settings

#### iOS Target (`T2S2T`):
1. Select project → Select `T2S2T` target
2. General tab:
   - Display Name: `T2S2T`
   - Bundle Identifier: `com.yourcompany.T2S2T`
   - Version: `1.0`
   - Build: `1`
   - Team: Select your Apple Developer Team
   - Minimum Deployments: iOS 16.0, iPadOS 16.0
3. Signing & Capabilities:
   - Enable "Automatically manage signing"
   - Select your Team
   - Capabilities should be auto-configured via entitlements

#### macOS Target (`T2S2TMac`):
1. Select `T2S2TMac` target
2. General tab:
   - Bundle Identifier: `com.yourcompany.T2S2T.mac`
   - Minimum Deployments: macOS 13.0
3. Signing & Capabilities:
   - Enable App Sandbox with Microphone access

#### watchOS Target (`T2S2TWatch`):
1. Select `T2S2TWatch` target
2. General tab:
   - Bundle Identifier: `com.yourcompany.T2S2T.watch`
   - Minimum Deployments: watchOS 9.0

### Step 4: Verify File References

After project generation, verify these files are visible in Xcode:
```
T2S2T/
├── App/
│   └── T2S2TApp.swift
├── Views/
│   └── ConversationView.swift
├── Info.plist
└── T2S2T.entitlements

Shared/
├── Models/
│   ├── DataController.swift
│   ├── UserProfile+CoreData.swift
│   ├── Conversation+CoreData.swift
│   ├── ProgressEntry+CoreData.swift
│   └── T2S2T.xcdatamodeld/
├── Services/
│   ├── SpeechService.swift
│   └── LLMService.swift
└── Utilities/
    └── Configuration.swift
```

### Step 5: Set Environment Variables

For LLM API access, set environment variables:

1. Edit the scheme: Product → Scheme → Edit Scheme
2. Select "Run" → Arguments tab
3. Add Environment Variables:
   - `OPENAI_API_KEY`: (your OpenAI API key)
   - `ANTHROPIC_API_KEY`: (optional, Anthropic API key)

Or export in terminal:
```bash
export OPENAI_API_KEY='your-api-key'
export ANTHROPIC_API_KEY='your-api-key'
```

### Step 6: Build and Run

1. Select a simulator (e.g., iPhone 15 Pro)
2. Product → Build (Cmd+B) - Check for errors
3. Product → Run (Cmd+R)

### Expected Behavior

✅ **On Success:**
- App launches in simulator
- Main screen shows tab bar with Practice, Progress, Settings
- Speech recognition permission prompt appears
- No build errors

❌ **On Failure:**
- Check error messages in Xcode
- Ensure all files are added to correct targets
- Verify framework links (AVFoundation, Speech, CoreData, CloudKit)
- Run setup script again: `./setup_xcode_project.sh`

### Troubleshooting

**"Cannot find module" errors:**
- Ensure all Swift files are included in the target
- Check target membership in File Inspector (right sidebar)
- Regenerate project: `xcodegen generate`

**"Missing Core Data model":**
- Add `T2S2T.xcdatamodeld` to the target
- Ensure it's in the "Copy Bundle Resources" build phase
- Regenerate project: `xcodegen generate`

**"Speech recognition not authorized":**
- This is normal on simulator
- Test on physical device for full functionality

**"Code signing failed":**
- Configure Apple Developer Team in Xcode
- Enable automatic signing or create provisioning profiles

### Next Steps After Successful Build

1. Test speech recognition on physical device
2. Configure iCloud container in Apple Developer portal
3. Set up LLM API keys
4. Implement remaining features
5. Add unit tests
6. Prepare for TestFlight distribution

### Support

- `README.md` - General project information
- `PROJECT_SUMMARY.md` - Complete project overview
- `BUILD_TEST_GUIDE.md` - Testing and CI/CD guide
- `setup_xcode_project.sh` - Project generation script

For issues, check Xcode console logs or run:
```bash
xcodebuild -project T2S2T.xcodeproj -scheme T2S2T -showBuildTimingSummary