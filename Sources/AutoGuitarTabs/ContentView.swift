import SwiftUI

struct ContentView: View {
    @StateObject private var detectionManager = DetectionManager()
    @State private var currentURL: URL?
    @State private var selectedInstrument: Instrument = .guitar
    @State private var autoRefresh = true
    
    // Triggers for WebView actions
    @State private var reloadTrigger = 0
    @State private var goBackTrigger = 0
    
    @State private var zoomLevel = 100
    @State private var autoScrollEnabled = false
    @State private var scrollSpeed = 2.0

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 15) {
                Spacer()
                    .frame(height: 20)
                
                NowPlayingCard(track: detectionManager.currentTrack)
                
                InstrumentNavigationList(selectedInstrument: $selectedInstrument)
                
                Spacer()
                
                SidebarFooter(detectionManager: detectionManager, autoRefresh: $autoRefresh)
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
            .background(.ultraThinMaterial)
        } detail: {
            ZStack {
                if let url = currentURL {
                    ZStack(alignment: .bottom) {
                        ZStack {
                            WebView(url: url, reloadTrigger: $reloadTrigger, goBackTrigger: $goBackTrigger, zoomLevel: $zoomLevel, autoScrollEnabled: $autoScrollEnabled, scrollSpeed: $scrollSpeed)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(24)
                        
                        ControlPill(zoomLevel: $zoomLevel, autoScrollEnabled: $autoScrollEnabled, scrollSpeed: $scrollSpeed)
                            .padding(.bottom, 48)
                    }
                    .id("webview") // Keep identity stable
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 72))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.accentColor)
                        Text("Ready to learn a new song?")
                            .font(.title2.bold())
                        Text("Start playing on Spotify or YouTube to sync tabs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.underPageBackgroundColor))
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: { goBackTrigger += 1 }) {
                        Image(systemName: "chevron.left")
                    }
                    .help("Go Back")
                    
                    Button(action: { reloadTrigger += 1 }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Reload")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: detectionManager.currentTrack) { _, newTrack in
            if autoRefresh, let _ = newTrack {
                refreshTab()
            }
        }
        .onChange(of: selectedInstrument) { _, _ in
            refreshTab()
        }
    }

    private func refreshTab() {
        guard let track = detectionManager.currentTrack else { return }
        
        let typeMap: [Instrument: Int] = [.guitar: 200, .chords: 300, .bass: 400]
        let typeVal = typeMap[selectedInstrument] ?? 200
        
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

// MARK: - Sidebar Components

struct NowPlayingCard: View {
    let track: TrackInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: track?.source == "Spotify" ? "wave.3.forward" : "play.rectangle.fill")
                    .foregroundColor(track?.source == "Spotify" ? .green : .red)
                    .font(.caption)
                Text(track?.source ?? "No Source")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track?.title ?? "No Track Detected")
                    .font(.headline)
                    .lineLimit(2)
                Text(track?.artist ?? "Play music to sync tabs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct InstrumentNavigationList: View {
    @Binding var selectedInstrument: Instrument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Instruments")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 10)
            
            ForEach(Instrument.allCases) { instrument in
                HStack(spacing: 12) {
                    Image(systemName: instrument.icon)
                        .frame(width: 20)
                    Text(instrument.rawValue)
                    Spacer()
                    if selectedInstrument == instrument {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .background(selectedInstrument == instrument ? Color.accentColor.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    selectedInstrument = instrument
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct SidebarFooter: View {
    @ObservedObject var detectionManager: DetectionManager
    @Binding var autoRefresh: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Source Priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $detectionManager.priority) {
                        Text("Spotify").tag(SourcePriority.spotify)
                        Text("YouTube").tag(SourcePriority.youtube)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Toggle(isOn: $autoRefresh) {
                    Text("Auto-Refresh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.switch)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

struct ControlPill: View {
    @Binding var zoomLevel: Int
    @Binding var autoScrollEnabled: Bool
    @Binding var scrollSpeed: Double
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Button(action: { zoomLevel = max(50, zoomLevel - 10) }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.plain)
                
                Text("\(zoomLevel)%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 40)
                
                Button(action: { zoomLevel = min(200, zoomLevel + 10) }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .frame(height: 16)
            
            HStack(spacing: 12) {
                Button(action: { autoScrollEnabled.toggle() }) {
                    Image(systemName: autoScrollEnabled ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(autoScrollEnabled ? .accentColor : .primary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Auto-Scroll")
                
                if autoScrollEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $scrollSpeed, in: 0.5...10.0)
                            .frame(width: 80)
                            .controlSize(.small)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: autoScrollEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

enum Instrument: String, CaseIterable, Identifiable {
    case guitar = "Guitar Tab"
    case chords = "Chords"
    case bass = "Bass Tab"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .guitar: return "guitars"
        case .chords: return "music.note.list"
        case .bass: return "amplifier"
        }
    }
}
