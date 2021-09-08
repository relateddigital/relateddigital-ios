//
//  HeaderFooterView.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

/**
 Enumeration used to generate views for the header and footer of a section.
 
 - Class:              Will generate a view of the specified class.
 - Callback->ViewType: Will generate the view as a result of the given closure.
 */
enum HeaderFooterProvider<ViewType: UIView> {
    
    /**
     * Will generate a view of the specified class.
     */
    case `class`
    
    /**
     * Will generate the view as a result of the given closure.
     */
    case callback(()->ViewType)
    
    internal func createView() -> ViewType {
        switch self {
        case .class:
            return ViewType()
        case .callback(let builder):
            return builder()
        }
    }
}

/**
 * Represents headers and footers of sections
 */
enum HeaderFooterType {
    case header, footer
}

/**
 *  Struct used to generate headers and footers either from a view or a String.
 */
struct HeaderFooterView<ViewType: UIView> : ExpressibleByStringLiteral, HeaderFooterViewRepresentable {
    
    /// Holds the title of the view if it was set up with a String.
    var title: String?
    
    /// Generates the view.
    var viewProvider: HeaderFooterProvider<ViewType>?
    
    /// Closure called when the view is created. Useful to customize its appearance.
    var onSetupView: ((_ view: ViewType, _ section: Section) -> Void)?
    
    /// A closure that returns the height for the header or footer view.
    var height: (() -> CGFloat)?
    
    /**
     This method can be called to get the view corresponding to the header or footer of a section in a specific controller.
     
     - parameter section:    The section from which to get the view.
     - parameter type:       Either header or footer.
     - parameter controller: The controller from which to get that view.
     
     - returns: The header or footer of the specified section.
     */
    func viewForSection(_ section: Section, type: HeaderFooterType) -> UIView? {
        var view: ViewType?
        if type == .header {
            view = section.headerView as? ViewType ?? {
                let result = viewProvider?.createView()
                section.headerView = result
                return result
            }()
        } else {
            view = section.footerView as? ViewType ?? {
                let result = viewProvider?.createView()
                section.footerView = result
                return result
            }()
        }
        guard let v = view else { return nil }
        onSetupView?(v, section)
        return v
    }
    
    /**
     Initiates the view with a String as title
     */
    init?(title: String?) {
        guard let t = title else { return nil }
        self.init(stringLiteral: t)
    }
    
    /**
     Initiates the view with a view provider, ideal for customized headers or footers
     */
    init(_ provider: HeaderFooterProvider<ViewType>) {
        viewProvider = provider
    }
    
    /**
     Initiates the view with a String as title
     */
    init(unicodeScalarLiteral value: String) {
        self.title  = value
    }
    
    /**
     Initiates the view with a String as title
     */
    init(extendedGraphemeClusterLiteral value: String) {
        self.title = value
    }
    
    /**
     Initiates the view with a String as title
     */
    init(stringLiteral value: String) {
        self.title = value
    }
}

extension UIView {
    
    func eurekaInvalidate() {
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        setNeedsLayout()
    }
    
}

