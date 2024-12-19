//
//  RDReadWriteLock.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 19.11.2021.
//

import Foundation

class RDReadWriteLock {
    private let concurrentQueue: DispatchQueue

    init(label: String) {
        self.concurrentQueue = DispatchQueue(label: label, attributes: .concurrent)
    }

    /// Güvenli okuma işlemleri için
    func read<T>(closure: () -> T) -> T {
        return self.concurrentQueue.sync {
            return closure()
        }
    }

    /// Güvenli yazma işlemleri için
    func write(closure: @escaping () -> Void) {
        self.concurrentQueue.async(flags: .barrier) {
            closure()
        }
    }
}
