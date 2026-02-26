import Foundation
import Combine

struct TrackInfo: Equatable {
    let title: String
    let artist: String
    let source: String // "Spotify" or "YouTube"
}

class DetectionManager: ObservableObject {
    @Published var currentTrack: TrackInfo?
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
        if let spotifyTrack = pollSpotify() {
            if spotifyTrack != currentTrack {
                currentTrack = spotifyTrack
            }
            return
        }

        if let youtubeTrack = pollSafariYouTube() {
            if youtubeTrack != currentTrack {
                currentTrack = youtubeTrack
            }
            return
        }

        // If nothing is playing, we keep the last track or set to nil?
        // For now, let's just keep it or set to nil if both are definitely not playing.
        // But Spotify might be "paused", which AppleScript can detect.
    }

    private func pollSpotify() -> TrackInfo? {
        let scriptSource = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    return trackName & "|" & trackArtist
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
                if parts.count == 2 {
                    return TrackInfo(title: parts[0], artist: parts[1], source: "Spotify")
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
