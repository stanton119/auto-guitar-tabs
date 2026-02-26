import SwiftUI

struct ContentView: View {
    @StateObject private var detectionManager = DetectionManager()
    @State private var currentURL: URL?
    @State private var tabType = "Guitar Tab"
    @State private var autoRefresh = true
    
    // Triggers for WebView actions
    @State private var reloadTrigger = 0
    @State private var goBackTrigger = 0

    let tabTypes = ["Guitar Tab", "Chords", "Bass Tab"]

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(spacing: 15) {
                // Navigation Controls
                HStack(spacing: 10) {
                    Button(action: { goBackTrigger += 1 }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Go Back")
                    
                    Button(action: { reloadTrigger += 1 }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Reload")
                }
                .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let track = detectionManager.currentTrack {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No Track Detected")
                            .font(.headline)
                        Text("Play music to sync tabs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("Tab Type", selection: $tabType) {
                    ForEach(tabTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Picker("Priority", selection: $detectionManager.priority) {
                    Text("Spotify First").tag(SourcePriority.spotify)
                    Text("YouTube First").tag(SourcePriority.youtube)
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                HStack(spacing: 5) {
                    Toggle("Auto", isOn: $autoRefresh)
                        .labelsHidden()
                        .toggleStyle(.switch)
                    Text("Auto")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main View (WebView)
            ZStack {
                if let url = currentURL {
                    WebView(url: url, reloadTrigger: $reloadTrigger, goBackTrigger: $goBackTrigger)
                        .id("webview") // Keep identity stable
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Ready to learn a new song?")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Start playing on Spotify or YouTube")
                            .font(.subheadline)
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: detectionManager.currentTrack) { _, newTrack in
            if autoRefresh, let _ = newTrack {
                refreshTab()
            }
        }
        .onChange(of: tabType) { _, _ in
            refreshTab()
        }
    }

    private func refreshTab() {
        guard let track = detectionManager.currentTrack else { return }
        
        let typeMap = ["Guitar Tab": 200, "Chords": 300, "Bass Tab": 400]
        let typeVal = typeMap[tabType] ?? 200
        
        var components = URLComponents(string: "https://www.ultimate-guitar.com/search.php")!
        components.queryItems = [
            URLQueryItem(name: "value", value: "\(track.artist) \(track.title)"),
            URLQueryItem(name: "type[]", value: String(typeVal))
        ]
        
        if let url = components.url {
            if self.currentURL != url {
                self.currentURL = url
            }
        }
    }
}
