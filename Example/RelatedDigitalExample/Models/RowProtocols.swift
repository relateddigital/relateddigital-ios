//
//  RowProtocols.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

/**
 *  Base protocol for view controllers presented by Eureka rows.
 */
protocol RowControllerType: NSObjectProtocol {

    /// A closure to be called when the controller disappears.
    var onDismissCallback: ((UIViewController) -> Void)? { get set }
}

/**
 *  Protocol that view controllers pushed or presented by a row should conform to.
 */
protocol TypedRowControllerType: RowControllerType {
    associatedtype RowValue: Equatable

    /// The row that pushed or presented this controller
    var row: RowOf<Self.RowValue>! { get set }
}

// MARK: Header Footer Protocols

/**
 *  Protocol used to set headers and footers to sections.
 *  Can be set with a view or a String
 */
protocol HeaderFooterViewRepresentable {

    /**
     This method can be called to get the view corresponding to the header or footer of a section in a specific controller.
     
     - parameter section:    The section from which to get the view.
     - parameter type:       Either header or footer.
     - parameter controller: The controller from which to get that view.
     
     - returns: The header or footer of the specified section.
     */
    func viewForSection(_ section: Section, type: HeaderFooterType) -> UIView?

    /// If the header or footer of a section was created with a String then it will be stored in the title.
    var title: String? { get set }

    /// The height of the header or footer.
    var height: (() -> CGFloat)? { get set }
}

