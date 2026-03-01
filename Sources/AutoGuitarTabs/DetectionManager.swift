import Foundation
import Combine

struct TrackInfo: Equatable {
    let title: String
    let artist: String
    let source: String // "Spotify" or "YouTube"
}

enum SourcePriority: String {
    case spotify = "Spotify"
    case youtube = "YouTube"
}

class DetectionManager: ObservableObject {
    @Published var currentTrack: TrackInfo?
    @Published var priority: SourcePriority = .spotify
    private var timer: AnyCancellable?

    init() {
        startPolling()
    }

    func startPolling() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.poll()
            }
    }

    func poll() {
        let spotifyTrack = pollSpotify()
        let youtubeTrack = pollSafariYouTube()
        
        // Debug logging for debugging standalone bundle
        if spotifyTrack == nil && youtubeTrack == nil {
            // print("DetectionManager: No tracks detected.")
        } else if let track = spotifyTrack {
            // print("DetectionManager: Spotify detected: \(track.title)")
        } else if let track = youtubeTrack {
            // print("DetectionManager: YouTube detected: \(track.title)")
        }
        
        var selectedTrack: TrackInfo?
        
        if priority == .spotify {
            selectedTrack = spotifyTrack ?? youtubeTrack
        } else {
            selectedTrack = youtubeTrack ?? spotifyTrack
        }

        if selectedTrack != currentTrack {
            currentTrack = selectedTrack
        }
    }

    private func pollSpotify() -> TrackInfo? {
        let scriptSource = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackURL to spotify url of current track
                    return trackName & "|" & trackArtist & "|" & trackURL
                end if
            end tell
        end if
        return ""
        """
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if let stringResult = result.stringValue, !stringResult.isEmpty {
                let parts = stringResult.components(separatedBy: "|")
                if parts.count >= 3 {
                    let title = parts[0]
                    let artist = parts[1]
                    let url = parts[2]
                    
                    // Skip updates if it's an advertisement
                    if url.contains("spotify:ad") || artist == "Spotify" {
                        return nil
                    }
                    
                    return TrackInfo(title: title, artist: artist, source: "Spotify")
                }
            }
        }
        return nil
    }

    private func pollSafariYouTube() -> TrackInfo? {
        let scriptSource = """
        if application "Safari" is running then
            tell application "Safari"
                repeat with w in windows
                    repeat with t in tabs of w
                        if name of t contains "YouTube" then
                            return name of t
                        end if
                    end repeat
                end repeat
            end tell
        end if
        return ""
        """
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if let stringResult = result.stringValue, !stringResult.isEmpty {
                // YouTube titles usually look like "Song Name - Artist - YouTube" or "Artist - Song Name - YouTube"
                // This is a bit fragile but a good start.
                let cleanTitle = stringResult.replacingOccurrences(of: " - YouTube", with: "")
                let parts = cleanTitle.components(separatedBy: " - ")
                if parts.count >= 2 {
                    return TrackInfo(title: parts[1], artist: parts[0], source: "YouTube")
                } else {
                    return TrackInfo(title: cleanTitle, artist: "Unknown", source: "YouTube")
                }
            }
        }
        return nil
    }
}
