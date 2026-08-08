import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var reloadTrigger: Int
    @Binding var goBackTrigger: Int
    @Binding var goForwardTrigger: Int
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var zoomLevel: Int
    @Binding var autoScrollEnabled: Bool
    @Binding var scrollSpeed: Double
    let autoOpenFirstTab: Bool = true
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        webView.navigationDelegate = context.coordinator
        
        // Initial zoom
        webView.magnification = CGFloat(zoomLevel) / 100.0
        
        context.coordinator.canGoBackObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { webView, _ in
            canGoBack = webView.canGoBack
        }
        context.coordinator.canGoForwardObservation = webView.observe(\.canGoForward, options: [.initial, .new]) { webView, _ in
            canGoForward = webView.canGoForward
        }
        context.coordinator.autoOpenFirstTab = autoOpenFirstTab
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.autoOpenFirstTab = autoOpenFirstTab
        
        // Apply zoom level if it changed
        let targetMagnification = CGFloat(zoomLevel) / 100.0
        if nsView.magnification != targetMagnification {
            nsView.setMagnification(targetMagnification, centeredAt: .zero)
        }
        
        // Handle Auto-Scroll
        if autoScrollEnabled {
            let js = """
            window.currentScrollSpeed = \(scrollSpeed);
            if (!window.autoScrollInterval) {
                window.autoScrollInterval = setInterval(() => {
                    window.scrollBy(0, window.currentScrollSpeed);
                }, 50);
            }
            """
            nsView.evaluateJavaScript(js, completionHandler: nil)
        } else {
            let js = "if (window.autoScrollInterval) { clearInterval(window.autoScrollInterval); window.autoScrollInterval = null; }"
            nsView.evaluateJavaScript(js, completionHandler: nil)
        }
        
        // If the URL is different from the current one and it's not a back/forward action
        if nsView.url?.absoluteString != url.absoluteString && context.coordinator.lastLoadedURL != url {
            let request = URLRequest(url: url)
            nsView.load(request)
            context.coordinator.lastLoadedURL = url
        }
        
        if goBackTrigger > context.coordinator.lastGoBack {
            nsView.goBack()
            context.coordinator.lastGoBack = goBackTrigger
        }
        
        if goForwardTrigger > context.coordinator.lastGoForward {
            nsView.goForward()
            context.coordinator.lastGoForward = goForwardTrigger
        }
        
        if reloadTrigger > context.coordinator.lastReload {
            nsView.reload()
            context.coordinator.lastReload = reloadTrigger
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedURL: URL?
        var lastGoBack = 0
        var lastGoForward = 0
        var lastReload = 0
        var canGoBackObservation: NSKeyValueObservation?
        var canGoForwardObservation: NSKeyValueObservation?
        var autoOpenFirstTab = true
        
        deinit {
            canGoBackObservation?.invalidate()
            canGoForwardObservation?.invalidate()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard autoOpenFirstTab else { return }
            if webView.url?.absoluteString.contains("search.php") == true {
                let js = """
                (function() {
                    const searchKey = 'auto_nav_' + btoa(window.location.search);
                    if (sessionStorage.getItem(searchKey)) return;

                    if (window.UGAPP && window.UGAPP.store && window.UGAPP.store.page && window.UGAPP.store.page.data) {
                        const data = window.UGAPP.store.page.data;
                        const results = data.results || data.other_tabs || [];
                        
                        if (results.length > 0) {
                            const firstFreeTab = results.find(tab => {
                                const type = (tab.type || "").toLowerCase();
                                const isAllowedType = type === 'tab' || type === 'chords' || type === 'bass';
                                const rating = tab.rating || 0;
                                return isAllowedType && rating >= 3;
                            });
                            
                            if (firstFreeTab && firstFreeTab.tab_url) {
                                sessionStorage.setItem(searchKey, 'true');
                                window.location.href = firstFreeTab.tab_url;
                            }
                        }
                    }
                })();
                """
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}
