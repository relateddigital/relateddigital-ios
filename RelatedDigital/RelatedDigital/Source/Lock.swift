//
//  Lock.swift
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

import Foundation

public class Lock {
    private let lock = NSRecursiveLock()

    public init() {}
    
    public func sync(closure: () -> ()) {
        self.lock.lock()
        closure()
        self.lock.unlock()
    }
}
