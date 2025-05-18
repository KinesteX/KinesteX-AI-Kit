import SwiftUI
import WebKit

class DebugWKWebView: WKWebView {
    deinit {
        print("🗑️ KinesteX: WebView deinitialized")
    }
}
// Cross-platform WebView wrapper view
@available(iOS 13.0, macOS 10.15, *)
public struct WebViewWrapperView: View {
    let url: URL
    let apiKey: String
    let companyName: String
    let userId: String
    let data: [String: Any]?
    @Binding var isLoading: Bool
    let onMessageReceived: (KinestexMessage) -> Void
    @ObservedObject var webViewState: WebViewState
    
    public var body: some View {
#if os(iOS) || targetEnvironment(macCatalyst)
        WebViewWrapper(
            url: url,
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            data: data,
            isLoading: $isLoading,
            onMessageReceived: onMessageReceived,
            webViewState: webViewState
        )
#elseif os(macOS)
        WebViewWrapper(
            url: url,
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            data: data,
            isLoading: $isLoading,
            onMessageReceived: onMessageReceived,
            webViewState: webViewState
        )
#endif
    }
}

// Cross-platform WebView wrapper
#if os(iOS) || targetEnvironment(macCatalyst)
struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    let apiKey: String
    let companyName: String
    let userId: String
    let data: [String: Any]?
    @Binding var isLoading: Bool
    let onMessageReceived: (KinestexMessage) -> Void
    @ObservedObject var webViewState: WebViewState
    
    public func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        config.userContentController = contentController
        config.preferences = preferences
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        config.requiresUserActionForMediaPlayback = false
        
        let webView = DebugWKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        contentController.add(context.coordinator, name: "listener")
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        
        webView.load(URLRequest(url: url))
        
        DispatchQueue.main.async {
            self.webViewState.webView = webView
        }
        
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op for now
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoading: $isLoading,
            webViewState: webViewState,
            onMessageReceived: onMessageReceived,
            apiKey: apiKey,
            companyName: companyName,
            userId: userId,
            data: data,
            url: url
        )
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        let isLoading: Binding<Bool>
        let webViewState: WebViewState
        let onMessageReceived: (KinestexMessage) -> Void
        let apiKey: String
        let companyName: String
        let userId: String
        let data: [String: Any]?
        let url: URL
        
        init(
            isLoading: Binding<Bool>,
            webViewState: WebViewState,
            onMessageReceived: @escaping (KinestexMessage) -> Void,
            apiKey: String,
            companyName: String,
            userId: String,
            data: [String: Any]?,
            url: URL
        ) {
            self.isLoading = isLoading
            self.webViewState = webViewState
            self.onMessageReceived = onMessageReceived
            self.apiKey = apiKey
            self.companyName = companyName
            self.userId = userId
            self.data = data
            self.url = url
        }
        
        deinit {
            print("🗑️ KinesteX: Coordinator deinitialized")
        }
        
        public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("❌ KinesteX: Web content process terminated")
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            webView.configuration.userContentController.removeAllScriptMessageHandlers()
            webViewState.webView = nil
            isLoading.wrappedValue = false
        }
        
        @available(iOS 15.0, *)
        public func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
            return .grant
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if !isLoading.wrappedValue {
                isLoading.wrappedValue = true
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle navigation completion if needed
        }
        
        private func createPostMessageScript() -> String {
            var scriptData: [String: Any] = [
                "key": apiKey,
                "company": companyName,
                "userId": userId
            ]
            if let data = data {
                scriptData.merge(data) { _, new in new }
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: scriptData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return "window.postMessage(\(jsonString), '\(url.absoluteString)');"
            }
            return "window.postMessage({ 'key': '\(apiKey)', 'company': '\(companyName)', 'userId': '\(userId)' }, '\(url.absoluteString)');"
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "listener", let messageBody = message.body as? String,
               let data = messageBody.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let type = json["type"] as? String {
                let webViewMessage: KinestexMessage
                switch type {
                case "kinestex_launched":
                    webViewMessage = .kinestex_launched(json)
                case "finished_workout":
                    webViewMessage = .finished_workout(json)
                case "error_occurred":
                    webViewMessage = .error_occurred(json)
                case "exercise_completed":
                    webViewMessage = .exercise_completed(json)
                case "exit_kinestex":
                    webViewMessage = .exit_kinestex(json)
                case "workout_opened":
                    webViewMessage = .workout_opened(json)
                case "workout_started":
                    webViewMessage = .workout_started(json)
                case "plan_unlocked":
                    webViewMessage = .plan_unlocked(json)
                case "mistake":
                    webViewMessage = .mistake(json)
                case "successful_repeat":
                    webViewMessage = .reps(json)
                case "left_camera_frame":
                    webViewMessage = .left_camera_frame(json)
                case "returned_camera_frame":
                    webViewMessage = .returned_camera_frame(json)
                case "workout_overview":
                    webViewMessage = .workout_overview(json)
                case "exercise_overview":
                    webViewMessage = .exercise_overview(json)
                case "workout_completed":
                    webViewMessage = .workout_completed(json)
                case "kinestex_loaded":
                    webViewMessage = .kinestex_loaded(json)
                    if let webView = webViewState.webView {
                        let script = createPostMessageScript()
                        webView.evaluateJavaScript(script) { _, error in
                            if let error = error {
                                print("⚠️ KinesteX: JavaScript Error: \(error.localizedDescription)")
                            } else {
                                print("✅ KinesteX: Sent authentication message")
                            }
                        }
                    } else {
                        print("⚠️ KinesteX: WebView is not available")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            self.isLoading.wrappedValue = false
                        }
                    }
                default:
                    webViewMessage = .custom_type(json)
                }
                DispatchQueue.main.async {
                    self.onMessageReceived(webViewMessage)
                }
            }
        }
    }
}

#elseif os(macOS)
public struct WebViewWrapper: NSViewRepresentable {
    let url: URL
    let apiKey: String
    let companyName: String
    let userId: String
    let data: [String: Any]?
    @Binding var isLoading: Bool
    let onMessageReceived: (KinestexMessage) -> Void
    @ObservedObject var webViewState: WebViewState
    
    public func makeNSView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        contentController.add(context.coordinator, name: "listener")
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = true
        
        webView.load(URLRequest(url: url))
        
        DispatchQueue.main.async {
            self.webViewState.webView = webView
        }
        
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op for now
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        let parent: WebViewWrapper
        deinit {
            print("🗑️ Coordinator deinitialized")
        }
        init(parent: WebViewWrapper) {
            self.parent = parent
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if !parent.isLoading {
                parent.isLoading = true
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
        }
        
        private func createPostMessageScript() -> String {
            var scriptData: [String: Any] = [
                "key": parent.apiKey,
                "company": parent.companyName,
                "userId": parent.userId
            ]
            if let data = parent.data {
                scriptData.merge(data) { _, new in new }
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: scriptData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return "window.postMessage(\(jsonString), '\(parent.url)');"
            }
            return "window.postMessage({ 'key': '\(parent.apiKey)', 'company': '\(parent.companyName)', 'userId': '\(parent.userId)' }, '\(parent.url)');"
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "listener", let messageBody = message.body as? String,
               let data = messageBody.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let type = json["type"] as? String {
                let webViewMessage: KinestexMessage
                switch type {
                case "kinestex_launched": webViewMessage = .kinestex_launched(json)
                case "finished_workout": webViewMessage = .finished_workout(json)
                case "error_occurred": webViewMessage = .error_occurred(json)
                case "exercise_completed": webViewMessage = .exercise_completed(json)
                case "exit_kinestex": webViewMessage = .exit_kinestex(json)
                case "workout_opened": webViewMessage = .workout_opened(json)
                case "workout_started": webViewMessage = .workout_started(json)
                case "plan_unlocked": webViewMessage = .plan_unlocked(json)
                case "mistake": webViewMessage = .mistake(json)
                case "successful_repeat": webViewMessage = .reps(json)
                case "left_camera_frame": webViewMessage = .left_camera_frame(json)
                case "returned_camera_frame": webViewMessage = .returned_camera_frame(json)
                case "workout_overview": webViewMessage = .workout_overview(json)
                case "exercise_overview": webViewMessage = .exercise_overview(json)
                case "workout_completed": webViewMessage = .workout_completed(json)
                case "kinestex_loaded":
                    webViewMessage = .kinestex_loaded(json)
                    if let webView = parent.webViewState.webView {
                        let script = createPostMessageScript()
                        webView.evaluateJavaScript(script) { _, error in
                            if let error = error {
                                print("⚠️ KinesteX: JavaScript Error: \(error.localizedDescription)")
                            } else {
                                print("✅ KinesteX: Sent authentication postMessage")
                            }
                        }
                    } else {
                        print("⚠️ KinesteX: WebView is not available")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            self.parent.isLoading = false
                        }
                    }
                default: webViewMessage = .custom_type(json)
                }
                DispatchQueue.main.async {
                    self.parent.onMessageReceived(webViewMessage)
                }
            }
        }
    }
}
#endif
