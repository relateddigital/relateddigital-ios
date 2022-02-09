//
//  RuleRange.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 9.02.2022.
//

import Foundation

public struct RuleGreaterThan<T: Comparable>: RuleType {

    let min: T

    public var id: String?
    var validationError: ValidationError

    public init(min: T, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "Field value must be greater than \(min)"
        self.min = min
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    func isValid(value: T?) -> ValidationError? {
        guard let val = value else { return nil }
        guard val > min else { return validationError }
        return nil
    }
}

public struct RuleGreaterOrEqualThan<T: Comparable>: RuleType {

    let min: T

    public var id: String?
    var validationError: ValidationError

    public init(min: T, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "Field value must be greater or equals than \(min)"
        self.min = min
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    func isValid(value: T?) -> ValidationError? {
        guard let val = value else { return nil }
        guard val >= min else { return validationError }
        return nil
    }
}

public struct RuleSmallerThan<T: Comparable>: RuleType {

    let max: T

    public var id: String?
    var validationError: ValidationError

    public init(max: T, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ??  "Field value must be smaller than \(max)"
        self.max = max
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    func isValid(value: T?) -> ValidationError? {
        guard let val = value else { return nil }
        guard val < max else { return validationError }
        return nil
    }
}

public struct RuleSmallerOrEqualThan<T: Comparable>: RuleType {

    let max: T

    public var id: String?
    var validationError: ValidationError

    public init(max: T, msg: String? = nil, id: String? = nil) {
        let ruleMsg = msg ?? "Field value must be smaller or equals than \(max)"
        self.max = max
        self.validationError = ValidationError(msg: ruleMsg)
        self.id = id
    }

    func isValid(value: T?) -> ValidationError? {
        guard let val = value else { return nil }
        guard val <= max else { return validationError }
        return nil
    }
}

