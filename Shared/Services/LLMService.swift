import Foundation
import Combine

class LLMService: ObservableObject {
    private var apiKey: String = ""
    private var currentProvider: AIProviderType = .openAI
    private var currentModel: String = ""
    
    private var urlSession: URLSession
    private var jsonDecoder: JSONDecoder
    private var jsonEncoder: JSONEncoder
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isConfigured = false
    
    init(urlSession: URLSession? = nil) {
        // Create a custom session configuration to handle proxy/TLS issues
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        config.urlCache = nil
        
        // Use system proxy settings but be more lenient with TLS
        if let session = urlSession {
            self.urlSession = session
        } else {
            self.urlSession = URLSession(configuration: config)
        }
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Configuration
    
    /// Configure with a specific provider
    func configure(provider: AIProviderType, apiKey: String, model: String? = nil) {
        self.currentProvider = provider
        self.apiKey = apiKey
        self.currentModel = model ?? provider.defaultModel
        self.isConfigured = true
    }
    
    /// Configure using environment variables based on selected provider
    func configureFromEnvironment() {
        let provider = Configuration.selectedAIProvider
        let apiKey = getAPIKey(for: provider)
        let model = getModel(for: provider)
        
        if !apiKey.isEmpty {
            configure(provider: provider, apiKey: apiKey, model: model)
        }
    }
    
    /// Get API key from environment for a specific provider
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
    
    /// Get model name for a specific provider
    private func getModel(for provider: AIProviderType) -> String {
        switch provider {
        case .openAI:
            return "gpt-4-turbo-preview"
        case .anthropic:
            return "claude-3-opus-20240229"
        case .qwen:
            return Configuration.qwenModel
        }
    }
    
    /// Check if a provider is properly configured
    func isProviderConfigured(_ provider: AIProviderType) -> Bool {
        return !getAPIKey(for: provider).isEmpty
    }
    
    /// Get the current provider's base URL
    private var baseURL: String {
        return currentProvider.baseURL
    }
    
    // MARK: - Public Methods
    
    func generateInitialPrompt(language: String, completion: @escaping (Result<String, Error>) -> Void) {
        let systemPrompt = """
        You are a friendly language learning assistant teaching \(language).
        Start a simple conversation to practice basic greetings and introductions.
        Keep your response to 1-2 sentences maximum.
        Speak naturally and encouragingly.
        """
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Start a conversation with me in \(language)"]
        ]
        
        generateCompletion(messages: messages, completion: completion)
    }
    
    func generateResponse(userInput: String, language: String, context: String = "", completion: @escaping (Result<String, Error>) -> Void) {
        let systemPrompt = """
        You are a language learning assistant teaching \(language).
        The user said: "\(userInput)"
        
        Teaching Guidelines:
        1. Respond ONLY in \(language)
        2. Keep responses concise (1-2 sentences)
        3. If the user makes errors, subtly correct them by:
           - Rephrasing correctly in your response
           - Asking a leading question
           - Never explicitly point out errors
        4. Continue the conversation naturally
        5. Adjust difficulty based on user's apparent level
        """
        
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userInput]
        ]
        
        if !context.isEmpty {
            messages.insert(["role": "assistant", "content": context], at: 1)
        }
        
        generateCompletion(messages: messages, completion: completion)
    }
    
    func analyzeErrors(userInput: String, targetLanguage: String, completion: @escaping (Result<ErrorAnalysis, Error>) -> Void) {
        let analysis = ErrorAnalysis(
            hasErrors: false,
            errors: [],
            suggestions: [],
            confidence: 1.0
        )
        completion(.success(analysis))
    }
    
    // MARK: - Private Methods
    
    private func generateCompletion(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(LLMError.missingAPIKey))
            return
        }
        
        isLoading = true
        error = nil
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set provider-specific headers
        switch currentProvider {
        case .openAI:
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        case .anthropic:
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .qwen:
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Build request body based on provider
        let requestBody: Any
        switch currentProvider {
        case .openAI, .qwen:
            requestBody = buildOpenAICompatibleRequest(messages: messages)
        case .anthropic:
            requestBody = buildAnthropicRequest(messages: messages)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            isLoading = false
            completion(.failure(error))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("LLMService: Network error: \(error.localizedDescription)")
                    self?.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("LLMService: No data received")
                    completion(.failure(LLMError.noData))
                    return
                }
                
                // Log response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("LLMService: Response: \(responseString.prefix(500))")
                }
                
                do {
                    let content = try self?.parseResponse(data: data)
                    if let content = content {
                        completion(.success(content))
                    } else {
                        print("LLMService: Failed to parse content from response")
                        completion(.failure(LLMError.invalidResponse))
                    }
                } catch {
                    print("LLMService: Parse error: \(error.localizedDescription)")
                    self?.error = error
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    private func buildOpenAICompatibleRequest(messages: [[String: String]]) -> [String: Any] {
        return [
            "model": currentModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 150
        ]
    }
    
    private func buildAnthropicRequest(messages: [[String: String]]) -> [String: Any] {
        // Convert messages to Anthropic format
        let systemMessage = messages.first { $0["role"] == "system" }
        let conversationMessages = messages.filter { $0["role"] != "system" }
        
        var body: [String: Any] = [
            "model": currentModel,
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        if let system = systemMessage {
            body["system"] = system["content"] ?? ""
        }
        
        body["messages"] = conversationMessages.map { msg -> [String: String] in
            var result: [String: String] = [:]
            if let role = msg["role"] {
                // Map user/assistant roles for Anthropic
                result["role"] = role == "assistant" ? "assistant" : "user"
            }
            if let content = msg["content"] {
                result["content"] = content
            }
            return result
        }
        
        return body
    }
    
    private func parseResponse(data: Data) throws -> String {
        // First, try to decode as an error response
        if let errorResponse = try? jsonDecoder.decode(APIErrorResponse.self, from: data),
           !errorResponse.error.message.isEmpty {
            throw LLMError.apiError(errorResponse.error.message)
        }
        
        switch currentProvider {
        case .openAI, .qwen:
            let response = try jsonDecoder.decode(ChatCompletionResponse.self, from: data)
            if let content = response.choices.first?.message.content {
                return content
            }
            // Check for finish reason
            if let firstChoice = response.choices.first,
               firstChoice.finishReason == "length" {
                throw LLMError.responseTruncated
            }
            throw LLMError.invalidResponse
            
        case .anthropic:
            let response = try jsonDecoder.decode(AnthropicResponse.self, from: data)
            if let content = response.content.first?.text {
                return content
            }
            throw LLMError.invalidResponse
        }
    }
    
    // MARK: - Mock/Preview Support
    
    static var mock: LLMService {
        let service = LLMService()
        service.configure(provider: .openAI, apiKey: "mock_key")
        return service
    }
}

// MARK: - Data Models

struct LLMMessage: Codable {
    let role: String
    let content: String
}

// OpenAI Compatible Response Models
struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: LLMMessage
        let finishReason: String?
    }
}

// Anthropic Response Model
struct AnthropicResponse: Codable {
    let content: [AnthropicContentBlock]
    
    struct AnthropicContentBlock: Codable {
        let type: String
        let text: String
    }
}

// MARK: - Error Analysis

struct ErrorAnalysis: Codable {
    let hasErrors: Bool
    let errors: [LanguageError]
    let suggestions: [String]
    let confidence: Double
}

struct LanguageError: Codable {
    let type: ErrorType
    let position: Range<Int>?
    let incorrect: String
    let correct: String?
    let explanation: String?
    
    enum ErrorType: String, Codable {
        case grammar
        case vocabulary
        case pronunciation
        case fluency
    }
}

// MARK: - API Error Response

struct APIErrorResponse: Codable {
    let error: APIError
    struct APIError: Codable {
        let message: String
        let type: String?
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case missingAPIKey
    case noData
    case invalidResponse
    case rateLimited
    case invalidAPIKey
    case providerNotConfigured
    case apiError(String)
    case responseTruncated
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please set up your LLM API key in settings."
        case .noData:
            return "No response received from the AI service."
        case .invalidResponse:
            return "Invalid response format from AI service."
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .providerNotConfigured:
            return "The selected AI provider is not configured. Please add your API key."
        case .apiError(let message):
            return "API Error: \(message)"
        case .responseTruncated:
            return "Response was truncated due to length limit."
        }
    }
}