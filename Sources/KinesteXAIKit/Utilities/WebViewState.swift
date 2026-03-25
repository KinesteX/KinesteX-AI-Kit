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

    deinit {
        print("🗑️ KinesteX: WebViewState deinitialized")
    }
}
