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
    @Published var errorMessage: String?
    @Published var isSpeaking = false
    
    var onRecognitionResult: ((String) -> Void)?
    var onSpeechCompletion: (() -> Void)?
    
    override init() {
        // Initialize with system language or default to English
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        self.speechRecognizer?.delegate = self
        self.speechSynthesizer.delegate = self
    }
    
    // MARK: - Speech Recognition
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    self.isAuthorized = true
                    self.requestMicrophonePermission()
                case .denied:
                    self.isAuthorized = false
                    self.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self.isAuthorized = false
                    self.errorMessage = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.isAuthorized = false
                @unknown default:
                    self.isAuthorized = false
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        #if os(iOS) || os(watchOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.errorMessage = "Microphone permission denied"
                }
            }
        }
        #elseif os(macOS)
        if #available(macOS 14.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.errorMessage = "Microphone permission denied"
                    }
                }
            }
        } else {
            // For macOS < 14, permission is handled by Info.plist and system prompt
            isAuthorized = true
        }
        #endif
    }
    
    func startRecording(languageCode: String = "en-US") throws {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode)) ?? speechRecognizer,
              recognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }
        
        // Cancel previous task if running
        stopRecording()
        
        // Create a new audio engine for each recording session
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.audioEngine = nil
            throw SpeechError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        engine.prepare()
        try engine.start()
        
        isRecording = true
        recognizedText = ""
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            // Capture values before Task to avoid data races
            let resultText = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            Task { @MainActor in
                if let text = resultText {
                    self.recognizedText = text
                    self.onRecognitionResult?(text)
                }
                
                if error != nil || isFinal {
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        // Stop recognition task first
        if let task = recognitionTask {
            task.cancel()
            recognitionTask = nil
        }
        
        // Stop and cleanup audio engine
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        isRecording = false
    }
    
    // MARK: - Speech Synthesis
    
    func speak(text: String, languageCode: String = "en-US", rate: Float = 0.5) {
        guard !text.isEmpty else { return }
        
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
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "Speech recognition is currently unavailable"
            }
        }
    }
    
    // MARK: - Error Handling
    
    enum SpeechError: LocalizedError {
        case recognizerNotAvailable
        case unableToCreateRequest
        case audioEngineError(Error)
        
        var errorDescription: String? {
            switch self {
            case .recognizerNotAvailable:
                return "Speech recognizer is not available for the selected language"
            case .unableToCreateRequest:
                return "Unable to create speech recognition request"
            case .audioEngineError(let error):
                return "Audio engine error: \(error.localizedDescription)"
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