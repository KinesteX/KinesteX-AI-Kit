//
//  WebViewState.swift
//  
//
//  Created by Vladimir Shetnikov on 5/13/25.
//


import WebKit
import Combine

class WebViewState: ObservableObject {
    @Published var webView: WKWebView?
    
    deinit {
        print("🗑️ KinesteX: WebViewState deinitialized")
    }
    
}
