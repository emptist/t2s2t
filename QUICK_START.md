# T2S2T Quick Start Guide

## Open and Run in Xcode - Step by Step

### Step 1: Open the Project

1. **Open Xcode**
2. Click "Open a project or file"
3. Navigate to: `/Users/jk/gits/hub/two_way_com_training/t2s2t`
4. **IMPORTANT: Select the ROOT `t2s2t` folder** (the one containing T2S2T/, T2S2TMac/, T2S2TWatch/)
5. If you have `T2S2T.xcodeproj` or `T2S2T.xcworkspace`, select it
6. If not, create a new project:

   a. File → New → Project
   b. Choose "Multiplatform App" template
   c. Product Name: `T2S2T`
   d. Organization: `com.yourcompany`
   e. Interface: SwiftUI
   f. Language: Swift
   g. Check "Use Core Data"
   h. Save in the **`t2s2t` root folder** (not in T2S2T subfolder)

### Step 2: Add Existing Files to the Project

After creating/opening the project:

1. In Xcode, right-click on the project in the navigator
2. Select "Add Files to T2S2T..."
3. Add the following folders (select each one):
   - `T2S2T/` - iOS app source code
   - `T2S2TMac/` - macOS app source code
   - `T2S2TWatch/` - watchOS app source code
   - `Shared/` - Shared code between platforms

4. In the dialog:
   - ✅ "Copy items if needed": **UNCHECKED** (we want to reference files)
   - ✅ "Create groups": Selected
   - ✅ Add to targets: Select appropriate targets for each file

### Step 3: Configure Target Settings

#### iOS Target (`T2S2T`):
1. Select project → Select `T2S2T` target
2. General tab:
   - Display Name: `T2S2T`
   - Bundle Identifier: `com.yourcompany.T2S2T`
   - Version: `1.0`
   - Build: `1`
   - Minimum Deployments: iOS 16.0, iPadOS 16.0
3. Signing & Capabilities:
   - Enable "Automatically manage signing"
   - Select your Team
   - Click "+ Capability" and add:
     - iCloud (with CloudKit)
     - App Groups
     - Background Modes (Audio, AirPlay, Picture in Picture)

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

1. Ensure these files are visible in Xcode:
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

2. Verify Core Data model:
   - Open `Shared/Models/T2S2T.xcdatamodeld/T2S2T.xcdatamodeld/contents`
   - Should contain UserProfile, Conversation, ProgressEntry entities

### Step 5: Set Environment Variables

For LLM API access, set environment variables:

1. Edit the scheme: Product → Scheme → Edit Scheme
2. Select "Run" → Arguments tab
3. Add Environment Variables:
   - `OPENAI_API_KEY`: (your OpenAI API key)
   - `ANTHROPIC_API_KEY`: (optional, Anthropic API key)

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

### Troubleshooting

**"Cannot find module" errors:**
- Ensure all Swift files are included in the target
- Check target membership in File Inspector (right sidebar)

**"Missing Core Data model":**
- Add `T2S2T.xcdatamodeld` to the target
- Ensure it's in the "Copy Bundle Resources" build phase

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
4. Implement remaining features according to the project architecture
5. Add unit tests
6. Prepare for TestFlight distribution

### Project Structure Summary

```
t2s2t/ (ROOT FOLDER - open this in Xcode)
├── T2S2T/              # iOS app
│   ├── App/
│   ├── Views/
│   ├── Info.plist
│   └── T2S2T.entitlements
├── T2S2TMac/          # macOS app
│   └── App/
├── T2S2TWatch/        # watchOS app
│   └── App/
├── Shared/            # Shared across all platforms
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── Documentation/     # Project docs
├── BUILD_TEST_GUIDE.md
├── IOS_CONFIGURATION_GUIDE.md
└── XCODE_WORKSPACE_GUIDE.md
```

### Support

- `README.md` - General project information
- `PROJECT_SUMMARY.md` - Complete project overview
- `BUILD_TEST_GUIDE.md` - Testing and CI/CD guide