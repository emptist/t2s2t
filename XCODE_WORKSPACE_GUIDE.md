# Xcode Workspace Configuration for T2S2T Multi-Platform Project

## Project Structure Overview

The project uses XcodeGen for project generation:

```
t2s2t/ (root folder)
├── project.yml              # XcodeGen configuration (edit this to modify targets)
├── setup_xcode_project.sh   # Script to generate Xcode project
├── T2S2T.xcodeproj/         # Generated Xcode project
├── T2S2T/                   # iOS app source code
├── T2S2TMac/                # macOS app source code
├── T2S2TWatch/              # watchOS app source code
├── Shared/                  # Shared code between platforms
└── *.md                     # Project documentation
```

## Step-by-Step Configuration

### Option A: Using the Setup Script (Recommended)

1. **Open Terminal** and navigate to the project root
2. **Run the setup script**:
   ```bash
   chmod +x setup_xcode_project.sh
   ./setup_xcode_project.sh
   ```

This script will:
- Check for XcodeGen installation
- Install XcodeGen if not present
- Generate the Xcode project
- Verify required files are present

### Option B: Manual Project Generation

1. **Install XcodeGen** if not already installed:
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode project**:
   ```bash
   xcodegen generate
   ```

3. **Open the project**:
   ```bash
   open T2S2T.xcodeproj
   ```

## Target Configuration for Each Platform

### iOS Target (`T2S2T`)
- **Source**: `T2S2T/` folder
- **Minimum Deployment**: iOS 16.0
- **Capabilities**: iCloud, Speech, Background Modes
- **Info.plist**: `T2S2T/Info.plist`
- **Entitlements**: `T2S2T/T2S2T.entitlements`

### macOS Target (`T2S2TMac`)
- **Source**: `T2S2TMac/` folder
- **Minimum Deployment**: macOS 13.0
- **Capabilities**: iCloud, Speech, App Sandbox
- **Entitlements**: `T2S2TMac/T2S2TMac.entitlements`

### watchOS Target (`T2S2TWatch`)
- **Source**: `T2S2TWatch/` folder
- **Minimum Deployment**: watchOS 9.0
- **Capabilities**: Limited speech recognition
- **Companion App**: References iOS app for data sync

## Shared Code Organization

Shared code is placed in the `Shared/` folder:
- `Shared/Services/` - SpeechService, LLMService (platform-agnostic)
- `Shared/Models/` - Data models, Core Data stack
- `Shared/Utilities/` - Configuration, helpers

These files are automatically included in all targets via XcodeGen.

## Modifying the Project

To add new files or modify targets, edit `project.yml`:

```yaml
targets:
  T2S2T:
    sources:
      - path: T2S2T
      - path: Shared
      - path: NewFolder  # Add new source folder
```

After editing `project.yml`, regenerate the project:
```bash
xcodegen generate
```

## Build Configuration Tips

1. **Build All Targets**: Product → Build For → Running
2. **Select Active Scheme**: Use scheme dropdown to switch between platforms
3. **Select Destination**: Choose simulator or device for each platform

## Verification Steps

After configuration:

1. **Build All Targets**: Product → Build For → Running
2. **Test on Simulators**: Run each target on appropriate simulator
3. **Verify Capabilities**: Check that speech recognition works on each platform
4. **Test Data Sync**: Create data on iOS, verify sync to macOS/watchOS

## Troubleshooting

**Issue**: "Missing source files" errors
**Solution**: 
- Ensure file references are in `project.yml`
- Regenerate project: `xcodegen generate`
- Check file paths are relative to project root

**Issue**: Capabilities not available on certain platforms
**Solution**: Some capabilities (Background Modes) are iOS-only; adjust per platform in Xcode

**Issue**: Code signing errors
**Solution**: Configure separate bundle identifiers for each target:
- iOS: `com.yourcompany.T2S2T`
- macOS: `com.yourcompany.T2S2T.mac`
- watchOS: `com.yourcompany.T2S2T.watch`

**Issue**: XcodeGen not generating correct project
**Solution**: Validate `project.yml` syntax:
```bash
xcodegen validate
```

## Next Steps

1. Run the setup script: `./setup_xcode_project.sh`
2. Open `T2S2T.xcodeproj` in Xcode
3. Configure signing for each target
4. Build and test on simulators
5. Configure CI/CD for multi-platform builds
6. Test on physical devices for full capability validation

## Summary

**Open the root `t2s2t` folder in Xcode** by first generating the project with XcodeGen, then opening `T2S2T.xcodeproj`. This approach provides:
- Centralized configuration via `project.yml`
- Shared code management
- Consistent build settings
- Efficient multi-platform development