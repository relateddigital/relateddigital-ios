//
//  RDStoryImageCache.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 18.12.2021.
//

import Foundation

private let oneHundredMB = 1024 * 1024 * 100

class RDStoryImageCache: NSCache<AnyObject, AnyObject> {
    static let shared = RDStoryImageCache()
    private override init() {
        super.init()
        self.setMaximumLimit()
    }
}

extension RDStoryImageCache {
    func setMaximumLimit(size: Int = oneHundredMB) {
        totalCostLimit = size
    }
}
