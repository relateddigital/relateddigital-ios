//
//  RDNpsWithNumbersDelegate.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 2.04.2023.
//

import Foundation


@objc
public protocol RDNpsWithNumbersDelegate: NSObjectProtocol {
    @objc
    func npsItemClicked(npsLink: String?)
}


