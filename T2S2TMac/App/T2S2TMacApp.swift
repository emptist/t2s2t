import SwiftUI

@main
struct T2S2TMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("T2S2T for macOS")
                .font(.title)
                .padding()
            Text("Voice-first language training")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Coming Soon")
                .font(.caption)
                .padding(.top, 20)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}