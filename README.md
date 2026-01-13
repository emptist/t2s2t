# T2S2T - Voice-First Language Training (Swift/iOS)

## Project Overview

A voice-first language training application for Apple ecosystem (iOS, iPadOS, watchOS, macOS) using Swift and SwiftUI. The app enables immersive conversational language learning through audio-only interactions with intelligent pedagogical feedback.

## Technology Stack

- **Language**: Swift 5+
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data + CloudKit
- **Audio Processing**: AVFoundation, Speech framework
- **Speech Recognition**: Speech framework (SFSpeechRecognizer)
- **Text-to-Speech**: AVSpeechSynthesizer
- **Networking**: URLSession for LLM API integration
- **Bluetooth**: CoreBluetooth for device sync
- **Watch Integration**: WatchKit for Apple Watch

## Project Structure

```
t2s2t/                      # ROOT FOLDER
├── project.yml             # XcodeGen configuration
├── setup_xcode_project.sh  # Project generation script
├── T2S2T/                  # iOS App
│   ├── App/
│   │   └── T2S2TApp.swift  # Main app entry point
│   ├── Views/
│   │   └── ConversationView.swift
│   ├── Info.plist
│   ├── T2S2T.entitlements
│   └── build_scripts/
├── T2S2TMac/               # macOS app
│   ├── App/
│   │   └── T2S2TMacApp.swift
│   └── T2S2TMac.entitlements
├── T2S2TWatch/             # Apple Watch app
│   └── App/
│       └── T2S2TWatchApp.swift
├── Shared/                 # Shared code between all targets
│   ├── Models/
│   │   ├── DataController.swift
│   │   ├── UserProfile+CoreData.swift
│   │   ├── Conversation+CoreData.swift
│   │   ├── ProgressEntry+CoreData.swift
│   │   └── T2S2T.xcdatamodeld/
│   ├── Services/
│   │   ├── SpeechService.swift
│   │   └── LLMService.swift
│   └── Utilities/
│       └── Configuration.swift
└── *.md                    # Documentation at root level
    ├── README.md
    ├── QUICK_START.md
    ├── BUILD_TEST_GUIDE.md
    └── ...
```

## Getting Started

### Prerequisites

- macOS with Xcode 15+
- iOS 17+ SDK
- Apple Developer Account (for deployment)
- Homebrew (recommended for installing XcodeGen)

### Setup

1. Clone the repository
2. Navigate to the `t2s2t` root folder
3. Run the setup script to generate the Xcode project:
   ```bash
   chmod +x setup_xcode_project.sh
   ./setup_xcode_project.sh
   ```
4. Open `T2S2T.xcodeproj` in Xcode
5. Configure signing certificates for each target
6. Set up LLM API keys in environment variables or Configuration.swift
7. Build and run on simulator or device

### Alternative: Manual Project Setup

If you prefer to set up the project manually:

1. Install XcodeGen: `brew install xcodegen`
2. Generate the project: `xcodegen generate`
3. Open `T2S2T.xcodeproj` in Xcode

### Configuration

#### AI Providers

The app supports multiple AI providers. You can choose from:

| Provider | Environment Variable | Default Model |
|----------|---------------------|---------------|
| OpenAI | `OPENAI_API_KEY` | gpt-4-turbo-preview |
| Anthropic | `ANTHROPIC_API_KEY` | claude-3-opus-20240229 |
| QWen (Alibaba) | `QWEN_API_KEY` | qwen-turbo |

Set environment variables:
```bash
# For OpenAI
export OPENAI_API_KEY='your-api-key'

# For Anthropic
export ANTHROPIC_API_KEY='your-api-key'

# For QWen
export QWEN_API_KEY='your-api-key'
export QWEN_MODEL='qwen-turbo'  # Optional: qwen-plus, qwen-max
export QWEN_BASE_URL='https://your-custom-endpoint.com/v1'  # Optional: custom endpoint
```

You can also configure your AI provider in the app settings (Settings tab).

#### Other Configuration

- iCloud container for sync
- App Groups for watchOS-iOS communication

## Core Features

### 1. Voice-First Interaction
- Speech-to-text for user input
- Text-to-speech for AI responses
- Voice activity detection
- Natural conversation flow

### 2. Intelligent Pedagogical Feedback
- Subtle error correction through conversational cues
- Grammar and vocabulary analysis
- Adaptive difficulty based on user level
- Progress tracking and analytics

### 3. Offline-First Architecture
- Core Data for local storage
- Full functionality without internet
- Smart sync when connection available

### 4. Cross-Device Synchronization
- iCloud sync across Apple devices
- AirDrop for local sharing
- Email export/import
- CoreBluetooth for direct device sync

### 5. Multi-Platform Support
- iOS (primary)
- iPadOS (adaptive layout)
- watchOS (quick practice sessions)
- macOS (Catalyst or native)

## Documentation

See the following documents:
- [`PROJECT_SUMMARY.md`](PROJECT_SUMMARY.md) - Project overview and implementation status
- [`swift_reevaluation.md`](swift_reevaluation.md) - Swift-specific analysis
- [`beam_moonbit_analysis.md`](beam_moonbit_analysis.md) - BEAM and MoonBit evaluation
- [`final_technology_recommendation.md`](final_technology_recommendation.md) - Final decision rationale
- [`XCODE_WORKSPACE_GUIDE.md`](XCODE_WORKSPACE_GUIDE.md) - XcodeGen setup guide
- [`T2S2T/IOS_CONFIGURATION_GUIDE.md`](T2S2T/IOS_CONFIGURATION_GUIDE.md) - iOS target configuration

## License

Proprietary - All rights reserved.