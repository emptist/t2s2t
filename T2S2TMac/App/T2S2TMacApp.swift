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
    @State private var currentLanguage = "English"
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Language Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Target Language")
                    .font(.headline)
                
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
                HStack(spacing: 12) {
                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title)
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                    .buttonStyle(.plain)
                    
                    TextField("Type or speak...", text: $userInput)
                        .textFieldStyle(.plain)
                        .disabled(isRecording || isProcessing)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(userInput.isEmpty || isProcessing)
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
                
                Spacer()
                
                // Status
                VStack(alignment: .leading, spacing: 4) {
                    StatusIndicator(label: "Speech", status: speechService.isAuthorized ? .ready : .pending)
                    StatusIndicator(label: "AI", status: llmService.isConfigured ? .ready : .pending)
                }
            }
            .frame(width: 160)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private func toggleRecording() {
        guard speechService.isAuthorized else {
            // Request authorization if not granted
            speechService.requestAuthorization()
            return
        }
        
        if isRecording {
            speechService.stopRecording()
            isRecording = false
        } else {
            Task { @MainActor in
                do {
                    try speechService.startRecording(languageCode: languageCode(currentLanguage))
                    isRecording = true
                } catch {
                    print("Failed to start recording: \(error)")
                    isRecording = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        let input = userInput
        userInput = ""
        isProcessing = true
        
        // Add user message
        conversation.append(ChatMessage(id: UUID(), role: .user, content: input))
        
        // Get AI response
        llmService.generateResponse(userInput: input, language: currentLanguage) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success(let response):
                    conversation.append(ChatMessage(id: UUID(), role: .assistant, content: response))
                case .failure(let error):
                    conversation.append(ChatMessage(id: UUID(), role: .assistant, content: "Sorry, I couldn't respond. Error: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func languageCode(_ language: String) -> String {
        switch language {
        case "Spanish": return "es-ES"
        case "French": return "fr-FR"
        case "German": return "de-DE"
        case "Japanese": return "ja-JP"
        case "Chinese": return "zh-CN"
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
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    if llmService.isProviderConfigured(provider) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
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
                .disabled(apiKey.isEmpty && selectedProvider != .qwen)
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
        let envKey = selectedProvider.apiKeyEnvironmentVariable
        setenv(envKey, apiKey, 1)
        
        if selectedProvider == .qwen {
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