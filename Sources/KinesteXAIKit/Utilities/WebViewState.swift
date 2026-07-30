//
//  WebViewState.swift
//  
//
//  Created by Vladimir Shetnikov on 5/13/25.
//


import WebKit
import Combine

@MainActor
public class WebViewState: ObservableObject {
    @Published public var webView: WKWebView?

    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Convenience accessor for the WKWebView's underlying UIScrollView.
    public var scrollView: UIScrollView? {
        webView?.scrollView
    }
    #endif

    public init() {}

    /// Posts an arbitrary JSON payload into the running KinesteX experience via
    /// `window.postMessage` — e.g. `["type": "update_trainer_profile", "age": 32]`.
    /// The web view must be loaded (pass this state object into the view factory).
    public func sendMessage(_ payload: [String: Any]) {
        guard let webView = webView else {
            print("⚠️ KinesteX: sendMessage failed — web view is not available yet")
            return
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("⚠️ KinesteX: sendMessage failed — payload is not valid JSON")
            return
        }
        webView.evaluateJavaScript("window.postMessage(\(jsonString), '*');") { _, error in
            if let error = error {
                print("⚠️ KinesteX: sendMessage JavaScript error: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        print("🗑️ KinesteX: WebViewState deinitialized")
    }
}
