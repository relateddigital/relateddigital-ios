//
//  Validation.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import Foundation

struct ValidationError: Equatable {

    let msg: String

    init(msg: String) {
        self.msg = msg
    }
}

func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
    return lhs.msg == rhs.msg
}

protocol BaseRuleType {
    var id: String? { get set }
    var validationError: ValidationError { get set }
}

protocol RuleType: BaseRuleType {
    associatedtype RowValueType

    func isValid(value: RowValueType?) -> ValidationError?
}

struct ValidationOptions: OptionSet {

    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let validatesOnDemand  = ValidationOptions(rawValue: 1 << 0)
    static let validatesOnChange  = ValidationOptions(rawValue: 1 << 1)
    static let validatesOnBlur = ValidationOptions(rawValue: 1 << 2)
    static let validatesOnChangeAfterBlurred = ValidationOptions(rawValue: 1 << 3)

    static let validatesAlways: ValidationOptions = [.validatesOnChange, .validatesOnBlur]
}

struct ValidationRuleHelper<T> where T: Equatable {
    let validateFn: ((T?) -> ValidationError?)
    let rule: BaseRuleType
}

struct RuleSet<T: Equatable> {

    internal var rules: [ValidationRuleHelper<T>] = []

    init() {}

    /// Add a validation Rule to a Row
    /// - Parameter rule: RuleType object typed to the same type of the Row.value
    mutating func add<Rule: RuleType>(rule: Rule) where T == Rule.RowValueType {
        let validFn: ((T?) -> ValidationError?) = { (val: T?) in
            return rule.isValid(value: val)
        }
        rules.append(ValidationRuleHelper(validateFn: validFn, rule: rule))
    }

    mutating func remove(ruleWithIdentifier identifier: String) {
        if let index = rules.firstIndex(where: { (validationRuleHelper) -> Bool in
            return validationRuleHelper.rule.id == identifier
        }) {
            rules.remove(at: index)
        }
    }

    mutating func removeAllRules() {
        rules.removeAll()
    }

}

