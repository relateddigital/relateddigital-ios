//
//  Helpers.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

extension UIView {

    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subView in subviews {
            if let firstResponder = subView.findFirstResponder() {
                return firstResponder
            }
        }
        return nil
    }

    func formCell() -> BaseCell? {
        if self is UITableViewCell {
            return self as? BaseCell
        }
        return superview?.formCell()
    }
}

extension NSPredicate {

    var predicateVars: [String] {
        var ret = [String]()
        if let compoundPredicate = self as? NSCompoundPredicate {
            for subPredicate in compoundPredicate.subpredicates where subPredicate is NSPredicate {
                ret.append(contentsOf: (subPredicate as! NSPredicate).predicateVars)
            }
        } else if let comparisonPredicate = self as? NSComparisonPredicate {
            ret.append(contentsOf: comparisonPredicate.leftExpression.expressionVars)
            ret.append(contentsOf: comparisonPredicate.rightExpression.expressionVars)
        }
        return ret
    }
}

extension NSExpression {

    var expressionVars: [String] {
        switch expressionType {
            case .function, .variable:
                let str = "\(self)"
                if let range = str.range(of: ".") {
                    return [String(str[str.index(str.startIndex, offsetBy: 1)..<range.lowerBound])]
                } else {
                    return [String(str[str.index(str.startIndex, offsetBy: 1)...])]
                }
            default:
                return []
        }
    }
}
