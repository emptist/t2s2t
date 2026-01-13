import SwiftUI

@main
struct T2S2TMacApp: App {
    @StateObject private var speechService = SpeechService()
    @StateObject private var llmService = LLMService()
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(speechService)
                .environmentObject(llmService)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    speechService.requestAuthorization()
                    llmService.configureFromEnvironment()
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .environmentObject(llmService)
                        .frame(minWidth: 520, minHeight: 500)
                }
                // Global keyboard shortcut: Enter sends text from anywhere
                .onKeyPress(.return) {
                    // Post notification that will be handled by PracticeView
                    NotificationCenter.default.post(name: NSNotification.Name("SendMessage"), object: nil)
                    return .handled
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About T2S2T") {
                    // About dialog handled by system
                }
            }
            CommandGroup(after: .appSettings) {
                Button("API Configuration...") {
                    showingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var llmService: LLMService
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            Picker("View", selection: $selectedTab) {
                Text("Practice").tag(0)
                Text("Progress").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Content
            TabView(selection: $selectedTab) {
                PracticeView()
                    .tag(0)
                
                ProgressViewMac()
                    .tag(1)
                
                SettingsContentView(showingSettings: $showingSettings)
                    .tag(2)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(llmService)
                .frame(minWidth: 520, minHeight: 500)
        }
    }
}

// MARK: - Practice View

struct PracticeView: View {
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var llmService: LLMService
    @State private var userInput = ""
    @State private var conversation: [ChatMessage] = []
    @State private var isRecording = false
    @State private var isConversationMode = false  // Continuous conversation mode
    @State private var currentLanguage = "English"
    @State private var isProcessing = false
    @State private var autoSpeak = true
    @State private var hasPendingAutoSend = false  // True when text is ready for auto-send
    @State private var wasEditedAfterRecognition = false  // True if user edited recognized text
    
    // Task to sync recognized text in real-time while recording
    @State private var syncTask: Task<Void, Never>?
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Language Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Target Language")
                    .font(.headline)
                
                LanguageButton(name: "English", flag: "🇺🇸", isSelected: currentLanguage == "English") {
                    currentLanguage = "English"
                }
                
                LanguageButton(name: "Spanish", flag: "🇪🇸", isSelected: currentLanguage == "Spanish") {
                    currentLanguage = "Spanish"
                }
                
                LanguageButton(name: "French", flag: "🇫🇷", isSelected: currentLanguage == "French") {
                    currentLanguage = "French"
                }
                
                LanguageButton(name: "German", flag: "🇩🇪", isSelected: currentLanguage == "German") {
                    currentLanguage = "German"
                }
                
                LanguageButton(name: "Japanese", flag: "🇯🇵", isSelected: currentLanguage == "Japanese") {
                    currentLanguage = "Japanese"
                }
                
                LanguageButton(name: "Chinese", flag: "🇨🇳", isSelected: currentLanguage == "Chinese") {
                    currentLanguage = "Chinese"
                }
                
                LanguageButton(name: "Esperanto", flag: "🌍", isSelected: currentLanguage == "Esperanto") {
                    currentLanguage = "Esperanto"
                }
                
                Spacer()
            }
            .frame(width: 180)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Middle Panel - Conversation
            VStack(spacing: 0) {
                // Conversation History
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            // AI Introduction
                            if conversation.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "waveform")
                                            .foregroundColor(.blue)
                                        Text("AI Assistant")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Hi! I'm your language practice assistant. I'll help you practice \(currentLanguage).")
                                        .padding()
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                            }
                            
                            ForEach(conversation) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.bottom)
                    }
                    .onChange(of: conversation.count) { _, _ in
                        if let lastMessage = conversation.last {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                VStack(spacing: 8) {
                    // Main input row with button and text field
                    HStack(spacing: 12) {
                        // Speak / Stop button - controls conversation mode
                        Button(action: toggleConversation) {
                            HStack(spacing: 6) {
                                Image(systemName: isConversationMode ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(isConversationMode ? "Stop" : "Speak")
                                    .font(.headline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isConversationMode ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                        }
                        .buttonStyle(.plain)
                        .help(isConversationMode ? "Stop conversation" : "Start speaking")
                        
                        // Text input field - ALWAYS visible
                        TextField("Type or speak here...", text: $userInput)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .disabled(isProcessing)
                            .onSubmit {
                                // Enter key sends the message
                                if !userInput.isEmpty {
                                    sendMessage()
                                }
                            }
                            .onChange(of: userInput) { _, newValue in
                                // If user edits text that was recognized from speech,
                                // disable auto-send and require manual send
                                if hasPendingAutoSend && isConversationMode {
                                    let wasRecognized = speechService.recognizedText
                                    // Check if the new value differs from what was recognized
                                    // (allowing for minor edits)
                                    if newValue != wasRecognized {
                                        wasEditedAfterRecognition = true
                                        hasPendingAutoSend = false
                                        print("[UI] User started editing recognized text - auto-send disabled")
                                    }
                                }
                            }
                        
                        // Send button - ALWAYS visible
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(userInput.isEmpty ? .gray : .blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(userInput.isEmpty || isProcessing)
                        
                        Spacer()
                    }
                    
                    // Status and audio level display
                    HStack(spacing: 8) {
                        // Recording indicator
                        if isConversationMode {
                            Circle()
                                .fill(speechService.isRecording ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(speechService.debugStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap 'Speak' or type to start")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Audio level visualization (when recording)
                        if isConversationMode {
                            AudioLevelView(level: speechService.audioLevel)
                                .frame(width: 60, height: 16)
                        }
                        
                        // Show recognized text while recording
                        if isConversationMode && !speechService.recognizedText.isEmpty {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text(speechService.recognizedText)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        
                        // Show auto-send indicator
                        if hasPendingAutoSend {
                            Text("• Will auto-send after silence")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        // Show edit indicator
                        if wasEditedAfterRecognition {
                            Text("• Edit detected - click Send to send")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            Divider()
            
            // Right Panel - Quick Actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                
                ActionButton(icon: "lightbulb", title: "Get Hint", color: .orange) {
                    // TODO: Implement hint feature
                }
                
                ActionButton(icon: "arrow.counterclockwise", title: "Start Over", color: .red) {
                    conversation.removeAll()
                    userInput = ""
                }
                
                // Auto-speak toggle
                Toggle("Auto Speak", isOn: $autoSpeak)
                    .font(.caption)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Spacer()
                
                // Status
                VStack(alignment: .leading, spacing: 4) {
                    StatusIndicator(label: "Speech", status: speechService.speechAuthorized ? .ready : .pending)
                    if !speechService.speechAuthorized && speechService.errorMessage != nil {
                        Text("Tap mic to enable")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    StatusIndicator(label: "AI", status: llmService.isConfigured ? .ready : .pending)
                    if llmService.isConfigured {
                        Text(Configuration.selectedAIProvider.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Debug status
                    Text(speechService.debugStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Error message
                    if let error = speechService.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(width: 160)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    // MARK: - Conversation Mode
    
    private func toggleConversation() {
        guard speechService.speechAuthorized else {
            // Request authorization if not granted
            speechService.requestAuthorization()
            return
        }
        
        if isConversationMode {
            // Stop the conversation
            stopConversation()
        } else {
            // Check if speech recognizer is available for this language
            guard speechService.recognizerAvailable else {
                // Show fallback message for unsupported languages
                let fallbackMessage = """
                Speech recognition is not supported for \(currentLanguage) on this Mac.
                
                Please type your message below and press Enter or click Send.
                
                Note: The AI can still understand and respond in \(currentLanguage).
                """
                conversation.append(ChatMessage(id: UUID(), role: .assistant, content: fallbackMessage))
                return
            }
            
            // Start a new conversation
            startConversation()
        }
    }
    
    private func startConversation() {
        print("[UI] Starting conversation mode")
        isConversationMode = true
        
        // Clear previous state
        speechService.recognizedText = ""
        userInput = ""
        
        // Set up silence detection callback
        speechService.onSilenceDetected = { [self] in
            guard isConversationMode else { return }
            print("[UI] ════════════════════════════════════════════════════════════")
            print("[UI] SILENCE DETECTED - processing recognized text...")
            print("[UI] Recognized text: '\(speechService.recognizedText)'")
            
            // Stop recording but keep conversation mode active
            speechService.stopRecording()
            
            // Sync recognized text to userInput
            if !speechService.recognizedText.isEmpty {
                userInput = speechService.recognizedText
                print("[UI] Text synced to input area")
                
                // Check if user has started editing (disable auto-send)
                wasEditedAfterRecognition = false
                hasPendingAutoSend = true
                
                // Auto-send recognized text (user can still click Send if not satisfied)
                print("[UI] AUTO-SENDING recognized text to AI...")
                print("[UI] Note: If you edit the text, auto-send will be disabled")
                sendToAI(text: userInput)
                userInput = ""
                hasPendingAutoSend = false
            } else {
                print("[UI] No text recognized - waiting for user input")
            }
            print("[UI] ════════════════════════════════════════════════════════════")
        }
        
        // Start listening - will auto-stop after 2.5s silence
        startListening()
    }
    
    private func stopConversation() {
        print("[UI] Stopping conversation mode")
        isConversationMode = false
        hasPendingAutoSend = false
        wasEditedAfterRecognition = false
        
        // Cancel sync task if running
        syncTask?.cancel()
        syncTask = nil
        
        // Sync recognized text to userInput so user can edit and send
        if !speechService.recognizedText.isEmpty {
            userInput = speechService.recognizedText
            print("[UI] Synced recognized text to input: '\(speechService.recognizedText)'")
        }
        
        // Disable streaming
        speechService.isAutoMode = false
        speechService.disableStreaming()
        speechService.stopRecording()
        speechService.stopSpeaking()
    }
    
    private func startListening() {
        guard isConversationMode else { return }
        
        Task { @MainActor in
            do {
                print("[UI] Starting to listen for \(currentLanguage)...")
                speechService.recognizedText = ""
                userInput = ""
                try speechService.startRecording(languageCode: languageCode(currentLanguage))
                
                // Start real-time sync of recognized text to userInput
                self.syncTask = Task { @MainActor [self] in
                    while !Task.isCancelled && self.isConversationMode {
                        // Sync recognized text to userInput as it comes in
                        if !self.speechService.recognizedText.isEmpty {
                            self.userInput = self.speechService.recognizedText
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    }
                }
            } catch {
                print("[UI] Speech recognition failed: \(error)")
                
                // Check if it's a recognizer not available error
                if let speechError = error as? SpeechService.SpeechError,
                   case .recognizerNotAvailable = speechError {
                    // Show fallback message for unsupported languages
                    let fallbackMessage = """
                    Speech recognition is not supported for \(currentLanguage) on this Mac.
                    
                    Please type your message below and press Enter or click Send.
                    
                    Note: The AI can still understand and respond in \(currentLanguage).
                    """
                    conversation.append(ChatMessage(id: UUID(), role: .assistant, content: fallbackMessage))
                    
                    // Exit conversation mode so user can type
                    isConversationMode = false
                    // Stop any pending auto-send state
                    hasPendingAutoSend = false
                    wasEditedAfterRecognition = false
                } else {
                    // Show generic error message
                    let errorMessage = getUserFriendlyErrorMessage(for: error)
                    conversation.append(ChatMessage(id: UUID(), role: .assistant, content: errorMessage))
                }
            }
        }
    }
    
    private func getUserFriendlyErrorMessage(for error: Error) -> String {
        // Check for specific speech recognition errors
        if let speechError = error as? SpeechService.SpeechError {
            return speechError.errorDescription ?? "Speech recognition error occurred"
        }
        
        // Check for common network/permission issues
        let errorCode = (error as NSError).code
        let domain = (error as NSError).domain
        
        print("[UI] Error details - domain: \(domain), code: \(errorCode)")
        
        // Permission-related errors
        if errorCode == 1 || errorCode == 168 || domain == "com.apple.speech.recognition" {
            return "Permission denied. Please grant microphone and speech recognition permissions in System Preferences > Privacy & Security."
        }
        
        // Microphone in use by another app
        if errorCode == -50 || errorCode == 561015949 || error.localizedDescription.contains("in use") {
            return "Microphone is in use by another application. Please close other apps using the microphone and try again."
        }
        
        // Network errors for speech recognition
        if errorCode == -1009 || errorCode == -1004 {
            return "Network unavailable. Speech recognition requires an internet connection. Please check your network settings."
        }
        
        // If we have a meaningful description, use it (check for unhelpful OSStatus errors)
        let description = error.localizedDescription
        if !description.isEmpty, description != "The operation couldn't be completed. (OSStatus error -50.)" {
            return "Error: \(description)"
        }
        
        // Fallback to a helpful message
        return "Unable to start listening. Please check your microphone connection and permissions, then try again."
    }
    
    private func sendToAI(text: String) {
        guard !text.isEmpty else {
            print("[UI] sendToAI called with empty text - ignoring")
            return
        }
        
        print("[UI] ════════════════════════════════════════════════════════════")
        print("[UI] SENDING TO AI:")
        print("[UI] Text: '\(text)'")
        print("[UI] Language: \(currentLanguage)")
        print("[UI] ════════════════════════════════════════════════════════════")
        
        isProcessing = true
        
        // Add user message to conversation
        conversation.append(ChatMessage(id: UUID(), role: .user, content: text))
        
        // Get AI response
        llmService.generateResponse(userInput: text, language: currentLanguage) { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let response):
                    // Add AI response to conversation
                    self.conversation.append(ChatMessage(id: UUID(), role: .assistant, content: response))
                    
                    // Speak the response if auto-speak is enabled
                    if self.autoSpeak {
                        self.speechService.speak(text: response, languageCode: self.languageCode(self.currentLanguage))
                        
                        // After TTS finishes, start listening again
                        self.speechService.onSpeechCompletion = {
                            DispatchQueue.main.async {
                                print("[UI] TTS finished, resuming listening...")
                                self.startListening()
                            }
                        }
                    } else {
                        // Start listening again immediately if no TTS
                        DispatchQueue.main.async {
                            self.startListening()
                        }
                    }
                    
                case .failure(let error):
                    self.conversation.append(ChatMessage(id: UUID(), role: .assistant, content: "Sorry, I couldn't respond. Error: \(error.localizedDescription)"))
                    // Try to continue the conversation
                    self.startListening()
                }
            }
        }
    }
    
    // MARK: - Sync recognized text to user input
    
    private func syncRecognizedText() {
        // Sync from speech service recognized text to user input
        if !speechService.recognizedText.isEmpty && speechService.recognizedText != userInput {
            userInput = speechService.recognizedText
        }
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty else {
            print("[UI] sendMessage called with empty userInput - ignoring")
            return
        }
        
        // Determine if this is recognized speech or typed text
        let isRecognizedSpeech = hasPendingAutoSend && !wasEditedAfterRecognition
        
        print("[UI] ════════════════════════════════════════════════════════════")
        if isRecognizedSpeech {
            print("[UI] Sending recognized text (user clicked Send): '\(userInput)'")
        } else {
            print("[UI] Sending typed text: '\(userInput)'")
        }
        print("[UI] ════════════════════════════════════════════════════════════")
        
        // Clear auto-send state
        hasPendingAutoSend = false
        wasEditedAfterRecognition = false
        
        sendToAI(text: userInput)
        userInput = ""
    }
    
    private func languageCode(_ language: String) -> String {
        switch language {
        case "Spanish": return "es-ES"
        case "French": return "fr-FR"
        case "German": return "de-DE"
        case "Japanese": return "ja-JP"
        case "Chinese": return "zh-CN"
        case "Esperanto": return "eo"  // Esperanto locale
        default: return "en-US"
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.role == .assistant {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                Text(message.role == .user ? "You" : "AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(message.content)
                .padding()
                .background(message.role == .user ? Color.blue.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

struct AudioLevelView: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                
                // Level indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(level > 0.01 ? Color.green : Color.clear)
                    .frame(width: max(0, CGFloat(level) * geometry.size.width))
            }
        }
    }
}

struct LanguageButton: View {
    let name: String
    let flag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(flag)
                Text(name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct StatusIndicator: View {
    let label: String
    let status: Status
    
    enum Status {
        case ready, pending, error
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .ready: return .green
        case .pending: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Progress View

struct ProgressViewMac: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Your Progress")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                HStack(spacing: 20) {
                    StatCard(title: "Total Practice", value: "0 min", icon: "clock.fill", color: .blue)
                    StatCard(title: "Conversations", value: "0", icon: "bubble.left.and.bubble.right.fill", color: .green)
                    StatCard(title: "Avg. Score", value: "--", icon: "star.fill", color: .orange)
                }
                .padding(.horizontal)
                
                Text("Progress tracking coming soon...")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(.top)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Settings Content View

struct SettingsContentView: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "gear.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("App Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Configure your AI provider and API keys to start practicing.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingSettings = true }) {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings View (Sheet)

struct SettingsView: View {
    @EnvironmentObject var llmService: LLMService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: AIProviderType = Configuration.selectedAIProvider
    @State private var apiKey: String = ""
    @State private var qwenModel: String = Configuration.qwenModel
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Content with ScrollView
            ScrollView {
                Form {
                    Section("AI Provider") {
                        ForEach(AIProviderType.allCases, id: \.self) { provider in
                            Button(action: {
                                selectedProvider = provider
                                apiKey = getAPIKey(for: provider)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(provider.displayName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text(provider.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if provider == selectedProvider {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Section("API Configuration") {
                        if selectedProvider == .qwen {
                            TextField("Model", text: $qwenModel)
                        }
                        
                        SecureField("API Key", text: $apiKey)
                    }
                    
                    Section {
                        Button(action: testConnection) {
                            HStack {
                                Text("Test Connection")
                                Spacer()
                                if isTesting {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isTesting)
                        
                        if !testResult.isEmpty {
                            Text(testResult)
                                .font(.caption)
                                .foregroundColor(testResult.contains("Success") ? .green : .red)
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("\(Configuration.appVersion) (\(Configuration.appBuild))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
                .padding()
            }
            
            Divider()
            
            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save & Close") {
                    saveConfiguration()
                    dismiss()
                }
                .disabled(!isValidAPIKey)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 500)
    }
    
    private func getAPIKey(for provider: AIProviderType) -> String {
        switch provider {
        case .openAI:
            return Configuration.openAIAPIKey
        case .anthropic:
            return Configuration.anthropicAPIKey
        case .qwen:
            return Configuration.qwenAPIKey
        }
    }
    
    private var isValidAPIKey: Bool {
        // QWen doesn't require API key for some endpoints
        if selectedProvider == .qwen {
            return true // Allow saving without key for QWen
        }
        return !apiKey.isEmpty
    }
    
    private func testConnection() {
        isTesting = true
        testResult = ""
        
        llmService.configure(provider: selectedProvider, apiKey: apiKey, model: qwenModel)
        llmService.generateInitialPrompt(language: "English") { result in
            DispatchQueue.main.async {
                isTesting = false
                switch result {
                case .success:
                    testResult = "Success! Connected to \(selectedProvider.displayName)"
                case .failure(let error):
                    testResult = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveConfiguration() {
        // Save API key to UserDefaults for persistence across app launches
        Configuration.saveAPIKey(apiKey, for: selectedProvider)
        
        if selectedProvider == .qwen {
            UserDefaults.standard.set(qwenModel, forKey: "QWEN_MODEL")
            UserDefaults.standard.set(qwenModel, forKey: "QWEN_MODEL")
        }
        
        llmService.configure(provider: selectedProvider, apiKey: apiKey, model: qwenModel)
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let role: Role
    let content: String
    
    enum Role {
        case user, assistant
    }
}