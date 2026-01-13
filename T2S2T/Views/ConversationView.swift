import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var llmService: LLMService
    @Environment(\.managedObjectContext) var moc
    
    @State private var conversationState: ConversationState = .idle
    @State private var aiResponse = ""
    @State private var userInput = ""
    @State private var showLanguagePicker = false
    @State private var selectedLanguage = "es" // Default to Spanish
    
    let supportedLanguages = [
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("ja", "Japanese"),
        ("zh", "Chinese"),
        ("ko", "Korean")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Language selector
                HStack {
                    Text("Practicing:")
                    Button(action: { showLanguagePicker.toggle() }) {
                        HStack {
                            Text(languageName(for: selectedLanguage))
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .popover(isPresented: $showLanguagePicker) {
                        LanguagePickerView(selectedLanguage: $selectedLanguage, languages: supportedLanguages)
                    }
                    
                    Spacer()
                    
                    if conversationState == .recording {
                        RecordingIndicatorView()
                    }
                }
                .padding(.horizontal)
                
                // AI Response Display
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !aiResponse.isEmpty {
                            AIResponseView(text: aiResponse)
                                .transition(.opacity)
                        }
                        
                        if !userInput.isEmpty {
                            UserInputView(text: userInput)
                                .transition(.opacity)
                        }
                        
                        if conversationState == .processing {
                            ProcessingIndicatorView()
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Controls
                VStack(spacing: 16) {
                    if conversationState == .idle {
                        Button(action: startConversation) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start Practice Session")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    } else if conversationState == .listening {
                        Button(action: stopRecording) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Recording")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    } else if conversationState == .waitingForResponse {
                        Text("AI is thinking...")
                            .foregroundColor(.secondary)
                    }
                    
                    if conversationState != .idle {
                        Button(action: resetConversation) {
                            Text("End Session")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: setupSpeechService)
            .alert("Error", isPresented: .constant(speechService.errorMessage != nil), actions: {
                Button("OK") {
                    speechService.errorMessage = nil
                }
            }, message: {
                if let error = speechService.errorMessage {
                    Text(error)
                }
            })
        }
    }
    
    // MARK: - Conversation Logic
    
    private func setupSpeechService() {
        speechService.onRecognitionResult = { text in
            userInput = text
        }
        
        speechService.onSpeechCompletion = {
            if self.conversationState == .speaking {
                self.startListening()
            }
        }
    }
    
    private func startConversation() {
        // Generate initial AI prompt
        conversationState = .processing
        llmService.generateInitialPrompt(language: selectedLanguage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.aiResponse = response
                    self.conversationState = .speaking
                    self.speechService.speak(text: response, languageCode: self.selectedLanguage)
                case .failure(let error):
                    self.conversationState = .idle
                    self.speechService.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func startListening() {
        conversationState = .listening
        userInput = ""
        
        do {
            try speechService.startRecording(languageCode: selectedLanguage)
            
            // Auto-stop after 10 seconds of silence
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.conversationState == .listening {
                    self.stopRecording()
                }
            }
        } catch {
            conversationState = .idle
            speechService.errorMessage = error.localizedDescription
        }
    }
    
    private func stopRecording() {
        speechService.stopRecording()
        conversationState = .processing
        
        // Process user input
        llmService.generateResponse(
            userInput: userInput,
            language: selectedLanguage,
            context: aiResponse
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.aiResponse = response
                    self.conversationState = .speaking
                    self.speechService.speak(text: response, languageCode: self.selectedLanguage)
                    
                    // Save conversation to Core Data
                    self.saveConversation()
                case .failure(let error):
                    self.conversationState = .waitingForResponse
                    self.speechService.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resetConversation() {
        speechService.stopRecording()
        speechService.stopSpeaking()
        conversationState = .idle
        aiResponse = ""
        userInput = ""
    }
    
    private func saveConversation() {
        // Implementation for saving to Core Data
        // This would create Conversation and ConversationExchange entities
    }
    
    private func languageName(for code: String) -> String {
        supportedLanguages.first { $0.0 == code }?.1 ?? code.uppercased()
    }
}

// MARK: - Supporting Views

struct AIResponseView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(text)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct UserInputView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Spacer()
                Text("You")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "person.circle")
                    .foregroundColor(.green)
            }
            
            Text(text)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct RecordingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 0.6).repeatForever(), value: isAnimating)
            
            Text("Listening...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear { isAnimating = true }
    }
}

struct ProcessingIndicatorView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Processing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    let languages: [(String, String)]
    
    var body: some View {
        List(languages, id: \.0) { code, name in
            HStack {
                Text(name)
                Spacer()
                if selectedLanguage == code {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedLanguage = code
            }
        }
        .frame(width: 200, height: 300)
    }
}

// MARK: - Conversation State

enum ConversationState {
    case idle
    case listening
    case processing
    case speaking
    case waitingForResponse
    case recording
}

// MARK: - Preview

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView()
            .environmentObject(SpeechService())
            .environmentObject(LLMService())
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}