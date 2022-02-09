//
//  RuleRequired.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 9.02.2022.
//

import Foundation

public struct RuleRequired<T: Equatable>: RuleType {

    public init(msg: String = "Field required!", id: String? = nil) {
        self.validationError = ValidationError(msg: msg)
        self.id = id
    }

    public var id: String?
    var validationError: ValidationError

    func isValid(value: T?) -> ValidationError? {
        if let str = value as? String {
            return str.isEmpty ? validationError : nil
        }
        return value != nil ? nil : validationError
    }
}
