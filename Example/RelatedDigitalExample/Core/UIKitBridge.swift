//
//  UIKitBridge.swift
//  RelatedDigitalExample
//
//  The SDK hands back UIKit views (story rail, banner carousel, NPS container,
//  button carousel). This wraps any of them for use inside SwiftUI.
//

import SwiftUI
import UIKit

/// Hosts an SDK-provided `UIView` and keeps it pinned to the SwiftUI frame.
struct HostedUIView: UIViewRepresentable {

    let view: UIView?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard container.subviews.first !== view else { return }
        container.subviews.forEach { $0.removeFromSuperview() }

        guard let view else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }
}

/// Resolves the topmost view controller — SDK entry points that present modally
/// occasionally need one, and SwiftUI does not expose it directly.
enum UIKitAccess {

    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    static var topViewController: UIViewController? {
        var controller = keyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
