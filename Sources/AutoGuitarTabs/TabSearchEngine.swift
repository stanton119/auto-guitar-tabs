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
        let typeMap = ["Guitar Tab": 200, "Chords": 300, "Bass Tab": 400]
        let typeVal = typeMap[type] ?? 200
        
        let query = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.ultimate-guitar.com/search.php?title=\(query)&type=\(typeVal)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
            throw NSError(domain: "TabSearchEngine", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access to Ultimate Guitar was blocked (403). Try again later."])
        }
        
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
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
            throw NSError(domain: "TabSearchEngine", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access to Ultimate Guitar was blocked (403) when fetching tab."])
        }
        
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
            print("Regex failed to match window.UGAPP in HTML. Length: \(html.count)")
            if html.contains("verification") || html.contains("captcha") {
                throw NSError(domain: "TabSearchEngine", code: 403, userInfo: [NSLocalizedDescriptionKey: "Ultimate Guitar is showing a captcha/verification page."])
            }
            return []
        }
        
        let jsonData = Data(html[range].utf8)
        let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let pageData = root?["data"] as? [String: Any]
        
        // UG changed their JSON structure sometimes. Let's check for 'other_tabs' or 'results'
        let results = pageData?["results"] as? [[String: Any]] ?? pageData?["other_tabs"] as? [[String: Any]] ?? []
        
        if results.isEmpty {
            print("No results found in JSON data.")
        }
        
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
