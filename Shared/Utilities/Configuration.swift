import Foundation

struct Configuration {
    // MARK: - API Keys
    // These should be stored securely in production
    // For development, use environment variables or Keychain in production
    
    static var openAIAPIKey: String {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    static var anthropicAPIKey: String {
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    }
    
    // MARK: - QWen (Local/Alibaba) API Configuration
    
    static var qwenAPIKey: String {
        ProcessInfo.processInfo.environment["QWEN_API_KEY"] ?? ""
    }
    
    static var qwenBaseURL: String {
        ProcessInfo.processInfo.environment["QWEN_BASE_URL"] ?? "https://dashscope.aliyuncs.com/compatible-mode/v1"
    }
    
    static var qwenModel: String {
        ProcessInfo.processInfo.environment["QWEN_MODEL"] ?? "qwen-turbo"
    }
    
    // MARK: - AI Provider Selection
    
    /// Currently selected AI provider
    static var selectedAIProvider: AIProviderType {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: "selectedAIProvider"),
                  let provider = AIProviderType(rawValue: rawValue) else {
                return .openAI
            }
            return provider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedAIProvider")
        }
    }
    
    // MARK: - App Configuration
    
    static let appName = "T2S2T"
    static let appVersion = "1.0.0"
    static let appBuild = "1"
    
    // MARK: - Feature Flags
    
    static var isCloudSyncEnabled: Bool {
        // iCloud sync requires Apple Developer Program with paid team
        // Personal development teams do not support CloudKit
        return false
    }
    
    static var isAnalyticsEnabled: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    static var isMockModeEnabled: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MOCK_MODE"] == "true"
        #else
        return false
        #endif
    }
    
    // MARK: - URLs
    
    static let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    static let termsOfServiceURL = URL(string: "https://example.com/terms")!
    static let supportURL = URL(string: "https://example.com/support")!
    
    // MARK: - Localization
    
    static let defaultLanguage = "en"
    static let supportedLanguages = ["en", "es", "fr", "de", "it", "ja", "zh", "ko"]
    
    // MARK: - Audio Settings
    
    static let defaultSpeechRate: Float = 0.5
    static let defaultSpeechPitch: Float = 1.0
    static let silenceTimeout: TimeInterval = 10.0
    static let maxRecordingDuration: TimeInterval = 60.0
    
    // MARK: - LLM Settings
    
    static let temperature: Double = 0.7
    static let maxTokens: Int = 500
    
    // MARK: - Sync Settings
    
    static let syncInterval: TimeInterval = 300
    static let maxSyncRetries = 3
    static let syncConflictResolution = ConflictResolutionStrategy.newestWins
    
    // MARK: - Analytics
    
    static let analyticsSampleRate: Double = 1.0
    static let sessionTimeout: TimeInterval = 1800
    
    // MARK: - Security
    
    static let encryptionAlgorithm = "AES-256-GCM"
    static let keychainServiceName = "com.t2s2t.app"
    static let keychainAccountName = "user_data"
}

// MARK: - Enums

enum ConflictResolutionStrategy {
    case newestWins
    case manual
    case merge
}

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

/// AI Provider types supported by the application
enum AIProviderType: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case qwen = "qwen"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .qwen:
            return "QWen (Alibaba)"
        }
    }
    
    var description: String {
        switch self {
        case .openAI:
            return "GPT-4 and GPT-3.5 models"
        case .anthropic:
            return "Claude models"
        case .qwen:
            return "QWen Turbo/Plus/Max models"
        }
    }
    
    var requiresAPIKey: Bool {
        return true
    }
    
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4-turbo-preview"
        case .anthropic:
            return "claude-3-opus-20240229"
        case .qwen:
            return "qwen-turbo"
        }
    }
    
    var apiKeyEnvironmentVariable: String {
        switch self {
        case .openAI:
            return "OPENAI_API_KEY"
        case .anthropic:
            return "ANTHROPIC_API_KEY"
        case .qwen:
            return "QWEN_API_KEY"
        }
    }
    
    var baseURL: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .qwen:
            // QWen compatible-mode endpoint
            return Configuration.qwenBaseURL.isEmpty
                ? "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
                : Configuration.qwenBaseURL + "/chat/completions"
        }
    }
    
    var supportsStreaming: Bool {
        switch self {
        case .openAI:
            return true
        case .anthropic:
            return true
        case .qwen:
            return true
        }
    }
}

// MARK: - Feature-Specific Configuration

struct SpeechConfiguration {
    static let sampleRate: Double = 16000.0
    static let bufferSize: Int = 1024
    static let voiceActivityThreshold: Float = -30.0 // dB
}

struct LLMConfiguration {
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 2
    static let cacheDuration: TimeInterval = 3600 // 1 hour
}

struct StorageConfiguration {
    static let maxStorageSize: Int64 = 100 * 1024 * 1024 // 100MB
    static let cleanupInterval: TimeInterval = 86400 // 1 day
}