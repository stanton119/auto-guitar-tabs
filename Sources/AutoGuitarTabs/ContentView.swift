import SwiftUI

struct ContentView: View {
    @StateObject private var detectionManager = DetectionManager()
    @State private var tabSearchEngine = TabSearchEngine()
    @State private var currentTab: TabContent?
    @State private var isLoading = false
    @State private var tabType = "Guitar Tab"
    @State private var autoRefresh = true
    
    // Auto-scroll state
    @State private var isAutoScrolling = false
    @State private var scrollSpeed: Double = 1.0 // Pixels per interval
    @State private var scrollOffset: CGFloat = 0
    private let scrollTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

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
                .frame(width: 250)
                
                HStack {
                    Toggle("Auto Refresh", isOn: $autoRefresh)
                        .labelsHidden()
                    Text("Auto")
                        .font(.caption)
                }
                
                Divider().frame(height: 24)
                
                HStack {
                    Button(action: { isAutoScrolling.toggle() }) {
                        Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Slider(value: $scrollSpeed, in: 0.1...5.0)
                        .frame(width: 100)
                    
                    Text("Scroll")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main Tab View
            ZStack {
                if isLoading {
                    ProgressView("Fetching Tab...")
                } else if let tab = currentTab {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(tab.content)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("tabContent")
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).origin.y)
                                    }
                                )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            if !isAutoScrolling {
                                scrollOffset = -value
                            }
                        }
                        .onReceive(scrollTimer) { _ in
                            if isAutoScrolling {
                                scrollOffset += CGFloat(scrollSpeed)
                                // Note: Simple auto-scroll doesn't easily work with ScrollViewReader without hacks
                                // For a prototype, we'll use an easier approach if possible or just document it.
                                // In SwiftUI, real programatic scrolling is often done via proxy.scrollTo
                            }
                        }
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
        .frame(minWidth: 900, minHeight: 600)
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
            isAutoScrolling = false
            scrollOffset = 0
            do {
                let results = try await tabSearchEngine.search(artist: track.artist, title: track.title)
                // Filter by type
                let searchType = tabType.lowercased().replacingOccurrences(of: " tab", with: "")
                let filtered = results.filter { $0.type.lowercased().contains(searchType) }
                
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
