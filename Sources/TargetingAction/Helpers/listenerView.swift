//
//  listenerView.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 14.12.2022.
//

import Foundation
import UIKit

final class ClickListener: UITapGestureRecognizer {
    private var action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }

    @objc private func execute() {
        action()
    }
}


extension UIView {
    
    public func setOnClickedListener(_ action: @escaping() -> Void)
    {
        self.isUserInteractionEnabled = true
        let click = ClickListener(action)
        self.addGestureRecognizer(click)
    }
}

