import Foundation

struct Configuration {
    // MARK: - API Keys
    // These should be stored securely in production
    // For development, use environment variables or a separate config file
    
    static var openAIAPIKey: String {
        // Read from environment variable or Keychain in production
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    static var anthropicAPIKey: String {
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    }
    
    // MARK: - App Configuration
    
    static let appName = "T2S2T"
    static let appVersion = "1.0.0"
    static let appBuild = "1"
    
    // MARK: - Feature Flags
    
    static var isCloudSyncEnabled: Bool {
        #if DEBUG
        return false // Disable in debug to avoid accidental data sync
        #else
        return true
        #endif
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
    static let silenceTimeout: TimeInterval = 10.0 // seconds
    static let maxRecordingDuration: TimeInterval = 60.0 // seconds
    
    // MARK: - LLM Settings
    
    static let defaultModel = "gpt-4-turbo-preview"
    static let fallbackModel = "gpt-3.5-turbo"
    static let temperature: Double = 0.7
    static let maxTokens: Int = 500
    
    // MARK: - Sync Settings
    
    static let syncInterval: TimeInterval = 300 // 5 minutes
    static let maxSyncRetries = 3
    static let syncConflictResolution = ConflictResolutionStrategy.newestWins
    
    // MARK: - Analytics
    
    static let analyticsSampleRate: Double = 1.0 // 100%
    static let sessionTimeout: TimeInterval = 1800 // 30 minutes
    
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
        // You might want to use a configuration flag or scheme to determine this
        return .production
        #endif
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