import Foundation
import Combine

class LLMService: ObservableObject {
    private var apiKey: String = ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private var urlSession: URLSession
    private var jsonDecoder: JSONDecoder
    
    @Published var isLoading = false
    @Published var error: Error?
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    func generateInitialPrompt(language: String, completion: @escaping (Result<String, Error>) -> Void) {
        let systemPrompt = """
        You are a friendly language learning assistant teaching \(language).
        Start a simple conversation to practice basic greetings and introductions.
        Keep your response to 1-2 sentences maximum.
        Speak naturally and encouragingly.
        """
        
        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: "Start a conversation with me in \(language)")
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
        
        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: userInput)
        ]
        
        if !context.isEmpty {
            // Include context from previous conversation
            let contextMessage = Message(role: "assistant", content: context)
            var allMessages = messages
            allMessages.insert(contextMessage, at: 1)
            generateCompletion(messages: allMessages, completion: completion)
        } else {
            generateCompletion(messages: messages, completion: completion)
        }
    }
    
    func analyzeErrors(userInput: String, targetLanguage: String, completion: @escaping (Result<ErrorAnalysis, Error>) -> Void) {
        // This would call a more specialized endpoint for error analysis
        // For now, return a simple analysis
        let analysis = ErrorAnalysis(
            hasErrors: false,
            errors: [],
            suggestions: [],
            confidence: 1.0
        )
        completion(.success(analysis))
    }
    
    // MARK: - Private Methods
    
    private func generateCompletion(messages: [Message], completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(LLMError.missingAPIKey))
            return
        }
        
        isLoading = true
        error = nil
        
        let requestBody = ChatCompletionRequest(
            model: "gpt-4-turbo-preview",
            messages: messages,
            temperature: 0.7,
            maxTokens: 150
        )
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            isLoading = false
            completion(.failure(error))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(LLMError.noData))
                    return
                }
                
                do {
                    let completionResponse = try self?.jsonDecoder.decode(ChatCompletionResponse.self, from: data)
                    if let content = completionResponse?.choices.first?.message.content {
                        completion(.success(content))
                    } else {
                        completion(.failure(LLMError.invalidResponse))
                    }
                } catch {
                    self?.error = error
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Mock/Preview Support
    
    static var mock: LLMService {
        let service = LLMService()
        service.configure(apiKey: "mock_key")
        return service
    }
}

// MARK: - Data Models

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
}

struct ChatCompletionResponse: Codable {
    let id: String
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String
    }
}

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

// MARK: - Errors

enum LLMError: LocalizedError {
    case missingAPIKey
    case noData
    case invalidResponse
    case rateLimited
    case invalidAPIKey
    
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
        }
    }
}