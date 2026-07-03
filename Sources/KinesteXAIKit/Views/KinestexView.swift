import SwiftUI
import WebKit
import Combine

struct KinestexView: View {
    let apiKey: String
    let companyName: String
    let userId: String
    let url: URL
    let data: [String: Any]?
    @Binding var isLoading: Bool
    let onMessageReceived: (KinestexMessage) -> Void
    let style: IStyle?
    @StateObject private var _internalWebViewState = WebViewState()
    let externalWebViewState: WebViewState?
    @State private var showOverlay: Bool = true
    @State private var showRetry: Bool = false
    @State private var launched: Bool = false
    @State private var retryMessage: String = ""
    @State private var launchTimer: DispatchWorkItem?
    @State private var didStartLaunch: Bool = false
    @Binding var currentExercise: String?
    @Binding var currentRestSpeech: String?
    @Binding var workoutAction: [String: Any]?

    /// The active WebViewState — uses external if provided, otherwise internal.
    var webViewState: WebViewState { externalWebViewState ?? _internalWebViewState }

    public init(
        apiKey: String,
        companyName: String,
        userId: String,
        url: URL,
        data: [String: Any]?,
        isLoading: Binding<Bool>,
        onMessageReceived: @escaping (KinestexMessage) -> Void,
        currentExercise: Binding<String?>,
        currentRestSpeech: Binding<String?>,
        workoutAction: Binding<[String: Any]?>,
        webViewState: WebViewState? = nil,
        style: IStyle?,
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
        self._workoutAction = workoutAction
        self.externalWebViewState = webViewState
        self.style = style
    }
    
    private var overlayColor: Color {
        if let hex = style?.loadingBackgroundColor {
            return Color.fromHex(hex)
        } else if style?.style == "light" {
            return .white
        } else {
            return .black
        }
    }

    /// Retry-screen foreground (matches the "dark mode" default from Flutter).
    private var foregroundColor: Color {
        style?.style == "light" ? .black : .white
    }

    private var connectionMessageText: String {
        connectionMessage(for: data?["language"])
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
                onMessageReceived: { message in
                    handle(message)
                },
                webViewState: webViewState
            )
//            if isLoading {
//                KinestexOverlayView(style: style)
//            }
            if showOverlay {
                KinestexOverlayView(style: style)
            }
            if showRetry {
                RetryView(
                    message: retryMessage.isEmpty ? connectionMessageText : retryMessage,
                    backgroundColor: overlayColor,
                    foregroundColor: foregroundColor,
                    onRetry: reload,
                    onBack: exitKinesteX
                )
            }
        }
        .background(overlayColor)
        .onAppear {
            // Start the 7s launch timer once, on first appearance.
            if !didStartLaunch {
                didStartLaunch = true
                startLaunchTimer()
            }
        }
        .onChange(of: currentExercise) { newValue in
            if let exercise = newValue {
                updateCurrentExercise(exercise)
            }
        }
        .onChange(of: currentRestSpeech) { newValue in
            if let restSpeech = newValue {
                updateCurrentRestSpeech(restSpeech)
            }
        }
        .onReceive(Just(workoutAction)) { newValue in
            guard let action = newValue, !action.isEmpty else { return }
            updateWorkoutAction(action)
        }
        .onDisappear {
            cancelLaunchTimer()
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
            if #available(iOS 15.0, macOS 12.0, *) {
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
    
    // MARK: - Retry logic

    /// Handles every message from the web view, then forwards it to the caller.
    private func handle(_ message: KinestexMessage) {
        switch message {
        case .kinestex_launched:
            launched = true
            cancelLaunchTimer()
            showRetry = false
        case .kinestex_loaded:
            cancelLaunchTimer()
            showRetry = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.showOverlay = false
            }
        case .error_occurred(let data):
            if !launched {
                showRetryScreen(errorMessage(from: data))
            }
        default:
            break
        }
        onMessageReceived(message)
    }

    /// Shows the retry screen if KinesteX doesn't launch within 7 seconds.
    private func startLaunchTimer() {
        cancelLaunchTimer()
        let work = DispatchWorkItem {
            print("⚠️ KinesteX: did not launch within 7s — showing retry")
            self.showRetryScreen(self.connectionMessageText)
        }
        launchTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: work)
    }

    private func cancelLaunchTimer() {
        launchTimer?.cancel()
        launchTimer = nil
    }

    private func showRetryScreen(_ message: String) {
        cancelLaunchTimer()
        retryMessage = message
        isLoading = false
        showRetry = true
    }

    /// Reloads the web view (the retry button's action).
    private func reload() {
        launched = false
        showRetry = false
        showOverlay = true
        startLaunchTimer()
        webViewState.webView?.load(URLRequest(url: url))
    }

    /// Back button on the retry screen — tells the host to close KinesteX.
    private func exitKinesteX() {
        let exitData: [String: Any] = [
            "type": "exit_kinestex",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        onMessageReceived(.exit_kinestex(exitData))
    }

    /// Pulls a human-readable message out of an error payload, or falls back
    /// to the localized "connect to the internet" message.
    private func errorMessage(from data: [String: Any]) -> String {
        var text: String?
        if let nested = data["data"] as? String {
            text = nested
        } else if let nested = data["data"] as? [String: Any], let message = nested["message"] as? String {
            text = message
        } else if let message = data["message"] as? String {
            text = message
        }
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? connectionMessageText : trimmed
    }

    private func updateCurrentExercise(_ exercise: String?) {
        guard let webView = webViewState.webView else {
            print("⚠️ KinesteX: WebView is not available")
            return
        }
        let script: String
        if let exercise = exercise {
            script = "window.postMessage({ 'currentExercise': '\(exercise)' }, '*');"
        } else {
            print("⚠️ KinesteX: Exercise is nil")
            return
        }
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("⚠️ KinesteX: JavaScript Error: \(error.localizedDescription)")
            } else {
                print("✅ KinesteX: Successfully updated exercise to: \(exercise ?? "NA")")
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
                print("✅ KinesteX: Successfully updated rest speech to: \(restSpeech ?? "NA")")
            }
        }
    }
    
    private func updateWorkoutAction(_ action: [String: Any]) {
        guard let webView = webViewState.webView else {
                print("⚠️ KinesteX: WebView not ready")
                return
            }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: action)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("⚠️ KinesteX: Cannot convert payload to JSON string")
                return
            }
            
            let script = """
            window.postMessage(\(jsonString), '*');
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    print("⚠️ KinesteX: Failed to send action payload: \(error)")
                } else {
                    print("→ Sent workout action payload: \(action)")
                }
            }
        } catch {
            print("⚠️ KinesteX: Failed to serialize action payload: \(error)")
            return
        }
    }

}

struct KinestexOverlayView: View {
    let style: IStyle?

    private var overlayColor: Color {
        if let hex = style?.loadingBackgroundColor {
            return Color.fromHex(hex)
        } else if style?.style == "light" {
            return .white
        } else {
            return .black
        }
    }

    var body: some View {
        overlayColor
            .ignoresSafeArea()
    }
}

/// Full-screen retry screen: a back button (top-left) and a centered refresh
/// icon + message. Tapping the center reloads the web view.
struct RetryView: View {
    let message: String
    let backgroundColor: Color
    let foregroundColor: Color
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            // Back button, top-left.
            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(foregroundColor)
                            .padding(26)
                    }
                    Spacer()
                }
                Spacer()
            }

            // Retry, centered.
            Button(action: onRetry) {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 48))
                        .foregroundColor(foregroundColor)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(foregroundColor)
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

/// Returns a localized "please connect to the internet" message for the given
/// language code (e.g. "en", "es", "pt-BR", "zh_CN"). Falls back to English.
func connectionMessage(for language: Any?) -> String {
    var code = (language as? String)?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
    // Keep only the primary subtag: "pt-BR" -> "pt", "zh_CN" -> "zh".
    code = code.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? ""
    // Normalize legacy codes.
    code = ["iw": "he", "in": "id"][code] ?? code
    return connectionMessages[code] ?? connectionMessages["en"]!
}

private let connectionMessages: [String: String] = [
    "en": "Please connect to the internet and try again",
    "ar": "يرجى الاتصال بالإنترنت والمحاولة مرة أخرى",
    "es": "Conéctate a Internet e inténtalo de nuevo",
    "it": "Connettiti a Internet e riprova",
    "he": "אנא התחבר לאינטרנט ונסה שוב",
    "zh": "请连接到互联网后重试",
    "pt": "Conecte-se à Internet e tente novamente",
    "uk": "Підключіться до Інтернету та повторіть спробу",
    "bn": "অনুগ্রহ করে ইন্টারনেটে সংযুক্ত হয়ে আবার চেষ্টা করুন",
    "ru": "Пожалуйста, подключитесь к интернету и повторите попытку",
    "hi": "कृपया इंटरनेट से कनेक्ट करें और पुनः प्रयास करें",
    "id": "Silakan sambungkan ke internet dan coba lagi",
    "fr": "Veuillez vous connecter à Internet et réessayer",
    "el": "Συνδεθείτε στο διαδίκτυο και δοκιμάστε ξανά",
    "nl": "Maak verbinding met internet en probeer het opnieuw",
    "de": "Bitte stellen Sie eine Internetverbindung her und versuchen Sie es erneut",
    "uz": "Iltimos, internetga ulaning va qayta urinib ko‘ring",
    "kk": "Интернетке қосылып, қайталап көріңіз",
    "ja": "インターネットに接続して、もう一度お試しください",
    "tr": "Lütfen internete bağlanın ve tekrar deneyin",
    "ko": "인터넷에 연결한 후 다시 시도해 주세요",
]
