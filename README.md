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
t2s2t/                      # ROOT FOLDER - Create Xcode project here
├── T2S2T/                  # iOS App
│   ├── App/
│   │   └── T2S2TApp.swift # Main app entry point
│   ├── Views/
│   │   └── ConversationView.swift
│   ├── build_scripts/
│   └── Resources/
├── T2S2TMac/              # macOS app
│   └── App/
├── T2S2TWatch/            # Apple Watch app
│   └── App/
├── Shared/                # Shared code between all targets
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
└── *.md                   # Documentation at root level
    ├── README.md
    ├── QUICK_START.md
    ├── BUILD_TEST_GUIDE.md
    └── ...
```

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

## Getting Started

### Prerequisites
- macOS with Xcode 15+
- iOS 17+ SDK
- Apple Developer Account (for deployment)

### Setup
1. Clone the repository
2. Open the ROOT `t2s2t` folder in Xcode (NOT the T2S2T subfolder)
3. Select `T2S2T.xcodeproj` to open
4. Configure signing certificates
5. Set up LLM API keys in environment variables or Configuration.swift
6. Build and run on simulator or device

### Configuration
- OpenAI/Anthropic API keys for LLM integration
- iCloud container for sync
- App Groups for watchOS-iOS communication

## Development Phases

### Phase 1: Foundation (Weeks 1-4)
- Project setup and Core Data schema
- Basic speech recognition/synthesis
- Simple conversation interface
- LLM integration prototype

### Phase 2: Core Features (Weeks 5-8)
- Pedagogical feedback system
- Progress tracking and analytics
- Settings and user profile
- Basic sync capabilities

### Phase 3: Platform Expansion (Weeks 9-12)
- iPadOS adaptive layout
- Apple Watch app
- macOS Catalyst app
- Advanced sync (iCloud, AirDrop)

### Phase 4: Polish (Weeks 13-16)
- Performance optimization
- Accessibility improvements
- Localization
- App Store submission

## Documentation

See the following analysis documents:
- [`architecture_comparison.md`](architecture_comparison.md) - Technology selection analysis
- [`swift_reevaluation.md`](swift_reevaluation.md) - Swift-specific analysis
- [`beam_moonbit_analysis.md`](beam_moonbit_analysis.md) - BEAM and MoonBit evaluation
- [`final_technology_recommendation.md`](final_technology_recommendation.md) - Final decision rationale

## License

Proprietary - All rights reserved.