//
//  RelatedDigitalReadWriteLock.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gulkilik on 6.07.2021.
//

import Foundation

class RelatedDigitalReadWriteLock {
    let concurentQueue: DispatchQueue

    init(label: String) {
        self.concurentQueue = DispatchQueue(label: label, attributes: .concurrent)
    }

    func read(closure: () -> Void) {
        self.concurentQueue.sync {
            closure()
        }
    }
    func write(closure: () -> Void) {
        self.concurentQueue.sync(flags: .barrier, execute: {
            closure()
        })
    }
}

