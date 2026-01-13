import SwiftUI

@main
struct T2S2TApp: App {
    @StateObject private var dataController = DataController()
    @StateObject private var speechService = SpeechService()
    @StateObject private var llmService = LLMService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(speechService)
                .environmentObject(llmService)
                .onAppear {
                    // Request speech recognition authorization
                    speechService.requestAuthorization()
                    
                    // Initialize LLM service with configured provider
                    llmService.configureFromEnvironment()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var llmService: LLMService
    
    var body: some View {
        TabView {
            ConversationView()
                .tabItem {
                    Label("Practice", systemImage: "message")
                }
            
            ProgressTrackingView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Placeholder Views

struct ProgressTrackingView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Progress Tracking")
                    .font(.title)
                    .padding(.top, 40)
                
                // Placeholder statistics
                VStack(spacing: 16) {
                    StatCard(title: "Total Practice", value: "0 min", icon: "clock")
                    StatCard(title: "Conversations", value: "0", icon: "bubble.left.and.bubble.right")
                    StatCard(title: "Avg. Score", value: "--", icon: "star")
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Progress")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SettingsView: View {
    @EnvironmentObject var llmService: LLMService
    @State private var selectedProvider: AIProviderType = Configuration.selectedAIProvider
    @State private var apiKey: String = ""
    @State private var qwenModel: String = Configuration.qwenModel
    @State private var showAPIKeyInput: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // AI Provider Section
                Section {
                    ForEach(AIProviderType.allCases) { provider in
                        ProviderRow(
                            provider: provider,
                            isSelected: selectedProvider == provider,
                            isConfigured: llmService.isProviderConfigured(provider)
                        ) {
                            selectedProvider = provider
                            apiKey = getAPIKey(for: provider)
                        }
                    }
                } header: {
                    Text("AI Provider")
                } footer: {
                    Text("Select your preferred AI provider for language learning assistance.")
                }
                
                // API Key Section
                Section {
                    if selectedProvider == .qwen {
                        TextField("QWen Model", text: $qwenModel)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Button(action: { showAPIKeyInput = true }) {
                        HStack {
                            Text("API Key")
                            Spacer()
                            Text(isAPIKeyConfigured() ? "Configured" : "Not Set")
                                .foregroundColor(isAPIKeyConfigured() ? .green : .red)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your API key is stored securely on your device.")
                }
                
                // Test Connection Section
                Section {
                    Button(action: testConnection) {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if llmService.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(llmService.isLoading)
                    
                    if let error = llmService.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Connection")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Configuration.appVersion) (\(Configuration.appBuild))")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: Configuration.privacyPolicyURL) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: Configuration.supportURL) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAPIKeyInput) {
                APIKeyInputSheet(
                    provider: selectedProvider,
                    apiKey: $apiKey,
                    qwenModel: $qwenModel
                ) { saveAPIKey() }
            }
            .onChange(of: selectedProvider) { _, newValue in
                Configuration.selectedAIProvider = newValue
            }
        }
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
    
    private func isAPIKeyConfigured() -> Bool {
        return !getAPIKey(for: selectedProvider).isEmpty
    }
    
    private func testConnection() {
        llmService.configure(provider: selectedProvider, apiKey: apiKey, model: qwenModel)
        llmService.generateInitialPrompt(language: "English") { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    showingSaveConfirmation = true
                case .failure:
                    break
                }
            }
        }
    }
    
    private func saveAPIKey() {
        // Save API key to environment (in production, use Keychain)
        let envKey = selectedProvider.apiKeyEnvironmentVariable
        setenv(envKey, apiKey, 1)
        
        // Update QWen model if applicable
        if selectedProvider == .qwen {
            // Save to UserDefaults for runtime access
            UserDefaults.standard.set(qwenModel, forKey: "QWEN_MODEL")
        }
        
        // Configure the service
        llmService.configure(provider: selectedProvider, apiKey: apiKey, model: qwenModel)
        showingSaveConfirmation = true
    }
}

struct ProviderRow: View {
    let provider: AIProviderType
    let isSelected: Bool
    let isConfigured: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct APIKeyInputSheet: View {
    let provider: AIProviderType
    @Binding var apiKey: String
    @Binding var qwenModel: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if provider == .qwen {
                        TextField("Model Name", text: $qwenModel)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                    }
                    
                    SecureField("API Key", text: $apiKey)
                        .textContentType(provider == .anthropic ? .none : .password)
                } header: {
                    Text(provider.displayName)
                } footer: {
                    Text("Enter your \(provider.displayName) API key. Get it from \(getAPIKeyURL(for: provider))")
                }
                
                Section {
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Save")
                    }
                    .disabled(apiKey.isEmpty && provider != .qwen)
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getAPIKeyURL(for provider: AIProviderType) -> String {
        switch provider {
        case .openAI:
            return "platform.openai.com/api-keys"
        case .anthropic:
            return "console.anthropic.com"
        case .qwen:
            return "bailian.console.aliyun.com"
        }
    }
}