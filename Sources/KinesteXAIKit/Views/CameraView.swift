import SwiftUI
import WebKit

public struct CameraView: View {
    let apiKey: String
    let companyName: String
    let userId: String
    let url: URL
    let data: [String: Any]?
    @Binding var isLoading: Bool
    let onMessageReceived: (WebViewMessage) -> Void
    @StateObject private var webViewState = WebViewState()
    @Binding var currentExercise: String
    @Binding var currentRestSpeech: String?
    
    public init(
        apiKey: String,
        companyName: String,
        userId: String,
        url: URL,
        data: [String: Any]?,
        isLoading: Binding<Bool>,
        onMessageReceived: @escaping (WebViewMessage) -> Void,
        currentExercise: Binding<String>,
        currentRestSpeech: Binding<String?>
    ) {
        self.apiKey = apiKey
        self.companyName = companyName
        self.userId = userId
        self.url = url
        self.data = data
        self._isLoading = isLoading
        self.onMessageReceived = onMessageReceived
        self._currentExercise = currentExercise
        self._currentRestSpeech = currentRestSpeech
    }
    
    public var body: some View {
        ZStack {
            WebViewWrapperView(
                url: url,
                apiKey: apiKey,
                companyName: companyName,
                userId: userId,
                data: data,
                isLoading: $isLoading,
                onMessageReceived: onMessageReceived,
                webViewState: webViewState
            )
            if isLoading {
               Color.black
            }
        }
        .background(Color.black)
        .onChange(of: currentExercise) { newValue in
            updateCurrentExercise(newValue)
        }
        .onChange(of: currentRestSpeech) { newValue in
            if let restSpeech = newValue {
                updateCurrentRestSpeech(restSpeech)
            }
        }
        .onDisappear {
            print("🗑️ KinesteX: cleaning up...")
            guard let webView = webViewState.webView else {
                print("⚠️ KinesteX: No web view to clean up")
                return
            }
            
            let cleanupScript = """
                (function() {
                    window.postMessage({ 'currentExercise': 'Stop Camera' }, '*');

                    document.querySelectorAll('video').forEach(function(video) {
                        video.pause();
                        video.src = '';
                        video.load();
                        video.remove();
                    });
                    document.querySelectorAll('audio').forEach(function(audio) {
                        audio.pause();
                        audio.src = '';
                        audio.load();
                        audio.remove();
                    });
                    if (window.stream) {
                        window.stream.getTracks().forEach(function(track) {
                            track.stop();
                        });
                        window.stream = null;
                    }
                    for (var id = setTimeout(() => {}, 0); id > 0; id--) {
                        clearTimeout(id);
                    }
                    for (var id = setInterval(() => {}, 0); id > 0; id--) {
                        clearInterval(id);
                    }
                    if (navigator.mediaSession) {
                        navigator.mediaSession.metadata = null;
                    }
                    if (window.gc) window.gc();
                })();
            """
            
            // Step 1: Pause all media playback (iOS 15.0+)
            if #available(iOS 15.0, *) {
                webView.pauseAllMediaPlayback {
                    runCleanupScript(webView, cleanupScript)
                }
            } else {
                runCleanupScript(webView, cleanupScript)
            }
        }
    }
    
    // Helper function to run cleanup script and proceed
    private func runCleanupScript(_ webView: WKWebView, _ script: String) {
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("⚠️ KinesteX: Error executing cleanup script: \(error)")
            } else {
                // Step 2: Load a blank page to reset state
                webView.load(URLRequest(url: URL(string: "about:blank")!))
                // Step 3: Perform final cleanup after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    webView.stopLoading()
                    webView.navigationDelegate = nil
                    webView.uiDelegate = nil
                    webView.configuration.userContentController.removeAllScriptMessageHandlers()
                    webView.configuration.userContentController.removeAllUserScripts()
                    
                    webViewState.webView = nil
                    print("✅ KinesteX: cleaned up and set webView to nil")
                }
            }
        }
    }
    
    private func updateCurrentExercise(_ exercise: String) {
        guard let webView = webViewState.webView else {
            print("⚠️ KinesteX: WebView is not available")
            return
        }
        let script = "window.postMessage({ 'currentExercise': '\(exercise)' }, '*');"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("⚠️ KinesteX: JavaScript Error: \(error.localizedDescription)")
            } else {
                print("✅ KinesteX: Successfully updated exercise to: \(exercise)")
            }
        }
    }
    
    private func updateCurrentRestSpeech(_ restSpeech: String?) { // Now accepts String?
        guard let webView = webViewState.webView else {
            print("⚠️ KinesteX: WebView is not available")
            return
        }
        let script: String
        if let restSpeech = restSpeech {
            script = "window.postMessage({ 'currentRestSpeech': '\(restSpeech)' }, '*');"
        } else {
            print("⚠️ KinesteX: Rest Speech is nil")
            return
        }
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("⚠️ KinesteX: JavaScript Error: \(error.localizedDescription)")
            } else {
                print("✅ KinesteX: Successfully updated rest speech to: \(restSpeech)")
            }
        }
    }
}
