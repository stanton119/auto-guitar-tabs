import Foundation

struct TabContent: Identifiable, Equatable {
    let id: Int
    let name: String
    let artist: String
    let type: String // "Tab", "Chords", "Bass"
    let rating: Double
    let votes: Int
    let content: String // The actual tab text
    let url: String
}

class TabSearchEngine {
    func search(artist: String, title: String, type: String = "Guitar Tab") async throws -> [TabContent] {
        let query = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.ultimate-guitar.com/search.php?search_type=title&value=\(query)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return try parseSearchResults(html: html)
    }

    func fetchTabContent(url: String) async throws -> String {
        guard let tabURL = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: tabURL)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return try parseTabHTML(html: html)
    }

    private func parseSearchResults(html: String) throws -> [TabContent] {
        let pattern = "window\\.UGAPP\\.store\\.page\\s*=\\s*(\\{.*?\\});"
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        guard let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return []
        }
        
        let jsonData = Data(html[range].utf8)
        let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let pageData = root?["data"] as? [String: Any]
        let results = pageData?["results"] as? [[String: Any]] ?? []
        
        return results.compactMap { (dict: [String: Any]) -> TabContent? in
            guard let id = dict["id"] as? Int,
                  let name = dict["song_name"] as? String,
                  let artist = dict["artist_name"] as? String,
                  let type = dict["type"] as? String,
                  let url = dict["tab_url"] as? String else {
                return nil
            }
            
            let rating = dict["rating"] as? Double ?? 0.0
            let votes = dict["votes"] as? Int ?? 0
            
            return TabContent(id: id, name: name, artist: artist, type: type, rating: rating, votes: votes, content: "", url: url)
        }
    }

    private func parseTabHTML(html: String) throws -> String {
        let pattern = "window\\.UGAPP\\.store\\.page\\s*=\\s*(\\{.*?\\});"
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        guard let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            throw NSError(domain: "TabSearchEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find tab data in HTML"])
        }
        
        let jsonData = Data(html[range].utf8)
        let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let pageData = root?["data"] as? [String: Any]
        let tabView = pageData?["tab_view"] as? [String: Any]
        let wikiTab = tabView?["wiki_tab"] as? [String: Any]
        
        return wikiTab?["content"] as? String ?? "No content found"
    }
}
