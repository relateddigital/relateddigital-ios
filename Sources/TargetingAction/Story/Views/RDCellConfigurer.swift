//
//  RDCellConfigurer.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import UIKit

protocol RDCellConfigurer: AnyObject {
    static var reuseIdentifier: String {get}
}

extension RDCellConfigurer {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionViewCell: RDCellConfigurer {}
extension UITableViewCell: RDCellConfigurer {}
