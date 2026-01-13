import Foundation
import Speech
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var isAuthorized = false
    @Published var speechAuthorized = false
    @Published var microphoneAuthorized = false
    @Published var errorMessage: String?
    @Published var isSpeaking = false
    @Published var debugStatus = "Initializing..."
    @Published var recognizerAvailable = false
    @Published var isAutoMode = false  // Auto-send mode for language practice
    @Published var streamingEnabled = false  // Enable smart streaming (pause detection)
    @Published var audioLevel: Float = 0.0  // For visualization
    
    var onRecognitionResult: ((String) -> Void)?
    var onSpeechCompletion: (() -> Void)?
    var onPartialResult: ((String) -> Void)?  // Called immediately for partial results
    var onFinalResult: ((String) -> Void)?  // Called when speech is detected as complete
    var onSilenceDetected: (() -> Void)?  // Called when silence is detected (for auto-stop)
    
    // MARK: - VAD Configuration (Audio Energy-Based)
    private let vadSilenceThreshold: Float = 0.01  // RMS threshold for silence (very quiet)
    private let vadSilenceDuration: TimeInterval = 2.5  // Stop after 2.5s of silence
    private let vadCheckInterval: TimeInterval = 0.1  // Check every 100ms
    
    // MARK: - VAD State
    private var isVoiceDetected = false
    private var silenceStartTime: Date?
    private var vadTimer: Timer?
    private var lastAudioLevel: Float = 0.0
    
    // MARK: - Streaming State
    private var lastPartialText: String = ""
    private var streamingCallback: ((String) -> Void)?
    
    // MARK: - Old Streaming Config (kept for reference)
    private let pauseBasedThreshold: TimeInterval = 7.0
    private let minWordsForSend: Int = 1
    
    override init() {
        // Initialize with system language or default to English
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        self.speechRecognizer?.delegate = self
        self.speechSynthesizer.delegate = self
        
        // Check initial availability
        self.recognizerAvailable = speechRecognizer?.isAvailable ?? false
        self.debugStatus = "Speech recognizer created"
        print("[SpeechService] Initialized with locale: en-US, available: \(self.recognizerAvailable)")
    }
    
    // MARK: - Speech Recognition
    
    func requestAuthorization() {
        print("[SpeechService] Requesting speech recognition authorization...")
        self.debugStatus = "Requesting speech recognition permission..."
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            Task { @MainActor in
                print("[SpeechService] Speech authorization status: \(String(describing: authStatus))")
                switch authStatus {
                case .authorized:
                    self.speechAuthorized = true
                    self.isAuthorized = true
                    self.debugStatus = "Speech authorized, requesting microphone..."
                    print("[SpeechService] Speech recognition authorized, requesting microphone permission")
                    self.requestMicrophonePermission()
                case .denied:
                    self.speechAuthorized = false
                    self.isAuthorized = false
                    self.errorMessage = "Speech recognition permission denied. Please enable it in System Preferences > Privacy & Security > Speech Recognition."
                    self.debugStatus = "Speech denied"
                    print("[SpeechService] Speech recognition denied")
                case .restricted:
                    self.speechAuthorized = false
                    self.isAuthorized = false
                    self.errorMessage = "Speech recognition restricted on this device"
                    self.debugStatus = "Speech restricted"
                    print("[SpeechService] Speech recognition restricted")
                case .notDetermined:
                    self.speechAuthorized = false
                    self.isAuthorized = false
                    self.debugStatus = "Speech not determined"
                    print("[SpeechService] Speech recognition not determined")
                @unknown default:
                    self.speechAuthorized = false
                    self.isAuthorized = false
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        print("[SpeechService] Requesting microphone permission...")
        self.debugStatus = "Requesting microphone permission..."
        
        #if os(iOS) || os(watchOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.microphoneAuthorized = true
                    self?.debugStatus = "Ready to record"
                    print("[SpeechService] Microphone permission granted (iOS)")
                } else {
                    self?.microphoneAuthorized = false
                    self?.errorMessage = "Microphone permission denied. Please enable it in System Preferences > Privacy & Security > Microphone."
                    self?.debugStatus = "Microphone denied"
                    print("[SpeechService] Microphone permission denied (iOS)")
                }
            }
        }
        #elseif os(macOS)
        if #available(macOS 14.0, *) {
            print("[SpeechService] Calling AVAudioApplication.requestRecordPermission...")
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                print("[SpeechService] Microphone permission callback received, granted: \(granted)")
                DispatchQueue.main.async {
                    if granted {
                        self?.microphoneAuthorized = true
                        self?.debugStatus = "Ready to record"
                        print("[SpeechService] Microphone permission granted (macOS 14+)")
                    } else {
                        self?.microphoneAuthorized = false
                        self?.errorMessage = "Microphone permission denied. Please enable it in System Preferences > Privacy & Security > Microphone."
                        self?.debugStatus = "Microphone denied"
                        print("[SpeechService] Microphone permission denied (macOS 14+)")
                    }
                }
            }
        } else {
            // For macOS < 14, permission is handled by Info.plist and system prompt
            self.microphoneAuthorized = true
            self.debugStatus = "Ready to record"
            print("[SpeechService] Microphone permission assumed (macOS < 14)")
        }
        #endif
    }
    
    func startRecording(languageCode: String = "en-US") throws {
        print("[SpeechService] === startRecording called with languageCode: \(languageCode) ===")
        errorMessage = nil
        
        // Check authorization status
        guard speechAuthorized else {
            print("[SpeechService] ERROR: Speech recognition not authorized")
            errorMessage = "Speech recognition not authorized. Please grant permission in System Preferences > Privacy & Security > Speech Recognition."
            throw SpeechError.notAuthorized
        }
        
        guard microphoneAuthorized else {
            print("[SpeechService] ERROR: Microphone not authorized")
            errorMessage = "Microphone not authorized. Please grant permission in System Preferences > Privacy & Security > Microphone."
            throw SpeechError.microphoneNotAuthorized
        }
        
        #if os(macOS)
        print("[SpeechService] macOS detected - using direct audio engine (no AVAudioSession)")
        #endif
        
        // Get or create recognizer
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode)) ?? speechRecognizer
        
        guard let speechRecognizer = recognizer else {
            print("[SpeechService] ERROR: No speech recognizer available")
            errorMessage = "No speech recognizer available for the selected language."
            throw SpeechError.recognizerNotAvailable
        }
        
        guard speechRecognizer.isAvailable else {
            print("[SpeechService] ERROR: Speech recognizer not available")
            errorMessage = "Speech recognizer is not available. Check your network connection and system settings."
            throw SpeechError.recognizerNotAvailable
        }
        
        print("[SpeechService] Speech recognizer is available")
        
        // Cancel previous task if running
        stopRecording()
        
        // Create a fresh audio engine
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        print("[SpeechService] Created new AVAudioEngine")
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.audioEngine = nil
            print("[SpeechService] ERROR: Unable to create recognition request")
            errorMessage = "Unable to create speech recognition request."
            throw SpeechError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        print("[SpeechService] Recognition request created")
        
        // Configure audio input
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        print("[SpeechService] Input node format: \(recordingFormat), sampleRate: \(recordingFormat.sampleRate), channelCount: \(recordingFormat.channelCount)")
        
        // Install tap for both speech recognition AND VAD
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, let request = self.recognitionRequest else { return }
            
            // Append buffer to speech recognition request
            request.append(buffer)
            
            // Calculate audio energy for VAD (on background queue)
            let level = self.calculateAudioLevel(buffer)
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
        
        // Start audio engine
        engine.prepare()
        
        // Try to start engine with retry logic
        var startError: Error?
        for attempt in 1...3 {
            do {
                try engine.start()
                print("[SpeechService] Audio engine started successfully on attempt \(attempt)")
                break
            } catch {
                startError = error
                print("[SpeechService] Attempt \(attempt) failed to start audio engine: \(error)")
                
                if attempt < 3 {
                    Thread.sleep(forTimeInterval: 0.5)
                    engine.stop()
                    let newEngine = AVAudioEngine()
                    self.audioEngine = newEngine
                    inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
                        guard let self = self, let request = self.recognitionRequest else { return }
                        request.append(buffer)
                        let level = self.calculateAudioLevel(buffer)
                        DispatchQueue.main.async {
                            self.audioLevel = level
                        }
                    }
                    newEngine.prepare()
                }
            }
        }
        
        if startError != nil && audioEngine?.isRunning != true {
            print("[SpeechService] ERROR: Failed to start audio engine after all attempts")
            self.audioEngine = nil
            errorMessage = "Failed to start audio engine. Please check your microphone is connected and not in use by another application."
            throw SpeechError.audioEngineError(startError!)
        }
        
        isRecording = true
        recognizedText = ""
        debugStatus = "Listening..."
        
        // Initialize VAD state
        resetVADState()
        
        // Start VAD timer
        startVADTimer()
        
        print("[SpeechService] Started recording, waiting for speech...")
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                print("[SpeechService] Recognition task error: \(error.domain) - \(error.code): \(error.localizedDescription)")
                
                // Check for common error codes that should be ignored
                // 216: No speech detected (user hasn't spoken yet)
                // 301: Recognition request was canceled (e.g., by VAD auto-stop)
                if error.code == 216 || error.code == 301 {
                    print("[SpeechService] Ignoring expected error code \(error.code)")
                    return
                }
                
                Task { @MainActor in
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopRecording()
                }
                return
            }
            
            if let result = result {
                let resultText = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                
                Task { @MainActor in
                    self.recognizedText = resultText
                    self.debugStatus = isFinal ? "Processing..." : "Listening..."
                    print("[SpeechService] Recognized: '\(resultText)' (final: \(isFinal))")
                    self.onRecognitionResult?(resultText)
                    
                    // Call partial result callback
                    if !isFinal && self.isAutoMode {
                        self.onPartialResult?(resultText)
                    }
                    
                    if isFinal {
                        print("[SpeechService] Final result received")
                        if self.isAutoMode {
                            self.onFinalResult?(resultText)
                        }
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        print("[SpeechService] stopRecording called, isRecording: \(isRecording)")
        
        // Stop VAD timer
        stopVADTimer()
        
        // Stop recognition task
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
            print("[SpeechService] Recognition task cancelled")
        }
        
        // Stop and cleanup audio engine
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
            print("[SpeechService] Audio engine stopped")
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        isRecording = false
        debugStatus = "Ready"
        audioLevel = 0.0
        
        print("[SpeechService] Recording stopped, recognized text: '\(recognizedText)'")
    }
    
    // MARK: - Voice Activity Detection (VAD)
    
    /// Reset VAD state for new recording session
    private func resetVADState() {
        isVoiceDetected = false
        silenceStartTime = nil
        lastAudioLevel = 0.0
        print("[SpeechService] VAD state reset")
    }
    
    /// Start VAD timer to monitor for silence
    private func startVADTimer() {
        vadTimer = Timer.scheduledTimer(withTimeInterval: vadCheckInterval, repeats: true) { [weak self] _ in
            self?.checkVAD()
        }
        print("[SpeechService] VAD timer started (\(vadCheckInterval)s interval, \(vadSilenceDuration)s silence threshold)")
    }
    
    /// Stop VAD timer
    private func stopVADTimer() {
        vadTimer?.invalidate()
        vadTimer = nil
        print("[SpeechService] VAD timer stopped")
    }
    
    /// Check for voice activity and silence
    private func checkVAD() {
        guard isRecording else { return }
        
        let currentLevel = audioLevel
        let now = Date()
        
        // Check if voice is detected (above threshold)
        if currentLevel > vadSilenceThreshold {
            isVoiceDetected = true
            silenceStartTime = nil
            lastAudioLevel = currentLevel
            
            // Only log occasionally to avoid spam
            if Int(now.timeIntervalSince1970) % 5 == 0 {
                print("[SpeechService] Voice detected, level: \(String(format: "%.4f", currentLevel))")
            }
        } else {
            // Voice not detected (silence)
            if isVoiceDetected {
                // Was speaking, now silence - start tracking silence duration
                if silenceStartTime == nil {
                    silenceStartTime = now
                    print("[SpeechService] Silence started, tracking...")
                }
                
                // Check if silence duration exceeds threshold
                if let silenceStart = silenceStartTime {
                    let silenceDuration = now.timeIntervalSince(silenceStart)
                    
                    // Update debug status with countdown
                    let remaining = max(0, vadSilenceDuration - silenceDuration)
                    if remaining < 0.1 || Int(remaining * 10) % 5 == 0 {
                        print("[SpeechService] Silence: \(String(format: "%.1f", silenceDuration))s / \(vadSilenceDuration)s threshold")
                    }
                    
                    if silenceDuration >= vadSilenceDuration {
                        // Silence threshold exceeded - auto-stop
                        print("[SpeechService] SILENCE DETECTED (\(String(format: "%.1f", silenceDuration))s), auto-stopping...")
                        
                        Task { @MainActor in
                            self.onSilenceDetected?()
                        }
                    }
                }
            }
        }
    }
    
    /// Calculate RMS (Root Mean Square) audio level from buffer
    /// Returns value between 0.0 (silence) and 1.0 (max volume)
    private func calculateAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        
        // Calculate RMS (Root Mean Square)
        for i in 0..<frameLength {
            let sample = channelData[0][i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        
        // Normalize to 0-1 range (approximate, as raw PCM values are typically -1.0 to 1.0)
        // Multiply by a factor to make it more visible
        let normalizedLevel = min(rms * 10.0, 1.0)
        
        return normalizedLevel
    }
    
    // MARK: - Smart Streaming (Simplified)
    
    /// Enable smart streaming with automatic pause detection
    func enableStreaming(callback: @escaping (String) -> Void) {
        streamingEnabled = true
        streamingCallback = callback
        lastPartialText = ""
        print("[SpeechService] Streaming enabled")
    }
    
    /// Disable streaming
    func disableStreaming() {
        streamingEnabled = false
        streamingCallback = nil
        print("[SpeechService] Streaming disabled")
    }
    
    // MARK: - Speech Synthesis
    
    func speak(text: String, languageCode: String = "en-US", rate: Float = 0.5) {
        guard !text.isEmpty else { return }
        
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            print("[SpeechService] Speech recognizer availability changed: \(available)")
            self.recognizerAvailable = available
            if !available {
                self.errorMessage = "Speech recognition is currently unavailable. Check your network connection and system settings."
                self.debugStatus = "Unavailable"
            } else {
                self.debugStatus = "Ready"
            }
        }
    }
    
    // MARK: - Error Handling
    
    enum SpeechError: LocalizedError {
        case recognizerNotAvailable
        case unableToCreateRequest
        case audioEngineError(Error)
        case audioSessionError(Error)
        case notAuthorized
        case microphoneNotAuthorized
        
        var errorDescription: String? {
            switch self {
            case .recognizerNotAvailable:
                return "Speech recognizer is not available for the selected language. Check your system settings."
            case .unableToCreateRequest:
                return "Unable to create speech recognition request"
            case .audioEngineError(let error):
                return "Audio engine error: \(error.localizedDescription)"
            case .audioSessionError(let error):
                return "Audio session error: \(error.localizedDescription)"
            case .notAuthorized:
                return "Speech recognition not authorized. Please grant permission in System Preferences."
            case .microphoneNotAuthorized:
                return "Microphone not authorized. Please grant permission in System Preferences."
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onSpeechCompletion?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Optional: Implement visual feedback for speech
    }
}