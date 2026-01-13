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
                    
                    // Initialize LLM service with API key from environment
                    if !Configuration.openAIAPIKey.isEmpty {
                        llmService.configure(apiKey: Configuration.openAIAPIKey)
                    }
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

// Placeholder views for missing components
struct ProgressTrackingView: View {
    var body: some View {
        VStack {
            Text("Progress Tracking")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            Text("Configuration options will appear here")
                .foregroundColor(.secondary)
        }
    }
}