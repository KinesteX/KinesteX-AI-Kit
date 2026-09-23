#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
import WebKit

@MainActor private var doneOnlyBarKey: UInt8 = 0

private final class DoneOnlyKeyboardBar: UIToolbar {
    weak var webView: WKWebView?

    // Blurring the element is what WebKit's own Done does; the keyboard follows.
    @objc func done() {
        webView?.evaluateJavaScript("document.activeElement && document.activeElement.blur()")
    }
}

extension WKWebView {
    // WebKit's keyboard bar (previous/next arrows + Done) has no public API, so the web
    // view's private content view is moved to a runtime subclass serving a Done-only bar.
    // It only swaps a bar WebKit already shows, so iPad (no bar) keeps its behavior.
    func useDoneOnlyKeyboardAccessory() {
        guard let contentView = scrollView.subviews.first(where: { NSStringFromClass(type(of: $0)).hasPrefix("WKContent") }),
              let contentClass = object_getClass(contentView) else { return }
        let subclassName = "\(NSStringFromClass(contentClass))_KinesteXDoneOnly"
        if let subclass = NSClassFromString(subclassName) {
            object_setClass(contentView, subclass)
            return
        }
        guard let subclass = objc_allocateClassPair(contentClass, subclassName, 0) else { return }
        let selector = #selector(getter: UIResponder.inputAccessoryView)
        typealias Getter = @convention(c) (AnyObject, Selector) -> UIView?
        let original = unsafeBitCast(class_getMethodImplementation(contentClass, selector), to: Getter.self)
        let accessory: @MainActor @convention(block) (UIView) -> UIView? = { view in
            guard original(view, selector) != nil else { return nil }
            if let bar = objc_getAssociatedObject(view, &doneOnlyBarKey) as? DoneOnlyKeyboardBar { return bar }
            let bar = DoneOnlyKeyboardBar()
            bar.webView = sequence(first: view, next: { $0.superview }).first { $0 is WKWebView } as? WKWebView
            let done = UIBarButtonItem(barButtonSystemItem: .done, target: bar, action: #selector(DoneOnlyKeyboardBar.done))
            // iOS 26 renders .done as a tinted circle; WebKit's own bar uses the neutral glass look.
            if #available(iOS 26.0, *) { done.style = .plain }
            bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
            bar.sizeToFit()
            objc_setAssociatedObject(view, &doneOnlyBarKey, bar, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bar
        }
        class_addMethod(subclass, selector, imp_implementationWithBlock(accessory), "@@:")
        objc_registerClassPair(subclass)
        object_setClass(contentView, subclass)
    }
}
#endif
