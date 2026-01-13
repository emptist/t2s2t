import SwiftUI

@main
struct T2S2TWatchApp: App {
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
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("T2S2T")
                .font(.headline)
                .padding(.top, 5)
            Text("Practice on the go")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("Coming Soon")
                .font(.caption)
                .padding(.top, 10)
        }
        .padding()
    }
}