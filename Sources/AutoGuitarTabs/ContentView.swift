import SwiftUI

struct ContentView: View {
    @StateObject private var detectionManager = DetectionManager()
    @State private var tabSearchEngine = TabSearchEngine()
    @State private var currentTab: TabContent?
    @State private var isLoading = false
    @State private var tabType = "Guitar Tab"
    @State private var autoRefresh = true

    let tabTypes = ["Guitar Tab", "Chords", "Bass Tab"]

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    if let track = detectionManager.currentTrack {
                        Text(track.title)
                            .font(.headline)
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No Track Detected")
                            .font(.headline)
                        Text("Play something on Spotify or YouTube")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Picker("Tab Type", selection: $tabType) {
                    ForEach(tabTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Toggle("Auto", isOn: $autoRefresh)
                    .toggleStyle(.switch)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main Tab View
            ZStack {
                if isLoading {
                    ProgressView("Fetching Tab...")
                } else if let tab = currentTab {
                    ScrollView {
                        Text(tab.content)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Tab Loaded")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: detectionManager.currentTrack) { _, newTrack in
            if autoRefresh, let track = newTrack {
                fetchTab(for: track)
            }
        }
        .onChange(of: tabType) { _, _ in
            if let track = detectionManager.currentTrack {
                fetchTab(for: track)
            }
        }
    }

    private func fetchTab(for track: TrackInfo) {
        Task {
            isLoading = true
            do {
                let results = try await tabSearchEngine.search(artist: track.artist, title: track.title)
                // Filter by type
                let filtered = results.filter { $0.type.lowercased() == tabType.lowercased().replacingOccurrences(of: " Tab", with: "").lowercased() }
                
                if let firstMatch = filtered.first ?? results.first {
                    let content = try await tabSearchEngine.fetchTabContent(url: firstMatch.url)
                    await MainActor.run {
                        self.currentTab = TabContent(
                            id: firstMatch.id,
                            name: firstMatch.name,
                            artist: firstMatch.artist,
                            type: firstMatch.type,
                            rating: firstMatch.rating,
                            votes: firstMatch.votes,
                            content: content,
                            url: firstMatch.url
                        )
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.currentTab = nil
                    }
                }
            } catch {
                print("Error fetching tab: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
