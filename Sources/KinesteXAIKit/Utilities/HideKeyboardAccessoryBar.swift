#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
import WebKit

extension WKWebView {
    // WebKit's keyboard bar (previous/next arrows + Done) has no public API, so the web
    // view's private content view is moved to a runtime subclass that returns no bar.
    func hideKeyboardAccessoryBar() {
        guard let contentView = scrollView.subviews.first(where: { NSStringFromClass(type(of: $0)).hasPrefix("WKContent") }),
              let contentClass = object_getClass(contentView) else { return }
        let subclassName = "\(NSStringFromClass(contentClass))_KinesteXNoAccessory"
        var subclass: AnyClass? = NSClassFromString(subclassName)
        if subclass == nil, let newClass = objc_allocateClassPair(contentClass, subclassName, 0) {
            let noBar: @convention(block) (AnyObject) -> UIView? = { _ in nil }
            class_addMethod(newClass, #selector(getter: UIResponder.inputAccessoryView), imp_implementationWithBlock(noBar), "@@:")
            objc_registerClassPair(newClass)
            subclass = newClass
        }
        if let subclass { object_setClass(contentView, subclass) }
    }
}
#endif
