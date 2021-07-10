//
//  Row.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import Foundation

class RowOf<T>: BaseRow where T: Equatable {

    private var _value: T? {
        didSet {
            guard _value != oldValue else { return }
            /*
            guard let form = section?.form else { return }
            if let delegate = form.delegate {
                delegate.valueHasBeenChanged(for: self, oldValue: oldValue, newValue: value)
                callbackOnChange?()
            }
            guard let t = tag else { return }
            form.tagToValues[t] = (value != nil ? value! : NSNull())
            if let rowObservers = form.rowObservers[t]?[.hidden] {
                for rowObserver in rowObservers {
                    (rowObserver as? Hidable)?.evaluateHidden()
                }
            }
            if let rowObservers = form.rowObservers[t]?[.disabled] {
                for rowObserver in rowObservers {
                    (rowObserver as? Disableable)?.evaluateDisabled()
                }
            }
            */
        }
    }

    /// The typed value of this row.
    open var value: T? {
        set (newValue) {
            _value = newValue
            guard let _ = section?.form else { return }
            wasChanged = true
            if validationOptions.contains(.validatesOnChange) || (wasBlurred && validationOptions.contains(.validatesOnChangeAfterBlurred)) ||  (!isValid && validationOptions != .validatesOnDemand) {
                validate()
            }
        }
        get {
            return _value
        }
    }
    
    /// The reset value of this row. Sets the value property to the value of this row on the resetValue method call.
    open var resetValue: T?

    /// The untyped value of this row.
    override var baseValue: Any? {
        get { return value }
        set { value = newValue as? T }
    }

    /// Block variable used to get the String that should be displayed for the value of this row.
    var displayValueFor: ((T?) -> String?)? = {
        return $0.map { String(describing: $0) }
    }

    required init(tag: String?) {
        super.init(tag: tag)
    }

    var rules: [ValidationRuleHelper<T>] = []

    @discardableResult
    open override func validate(quietly: Bool = false) -> [ValidationError] {
        var vErrors = [ValidationError]()
        vErrors = rules.compactMap { $0.validateFn(value) }
        if (!quietly) {
            validationErrors = vErrors
        }
        return vErrors
    }
    
    /// Resets the value of the row. Setting it's value to it's reset value.
    func resetRowValue() {
        value = resetValue
    }

    /// Add a Validation rule for the Row
    /// - Parameter rule: RuleType object to add
    func add<Rule: RuleType>(rule: Rule) where T == Rule.RowValueType {
        let validFn: ((T?) -> ValidationError?) = { (val: T?) in
            return rule.isValid(value: val)
        }
        rules.append(ValidationRuleHelper(validateFn: validFn, rule: rule))
    }

    /// Add a Validation rule set for the Row
    /// - Parameter ruleSet: RuleSet<T> set of rules to add
    func add(ruleSet: RuleSet<T>) {
        rules.append(contentsOf: ruleSet.rules)
    }

    func remove(ruleWithIdentifier identifier: String) {
        if let index = rules.firstIndex(where: { (validationRuleHelper) -> Bool in
            return validationRuleHelper.rule.id == identifier
        }) {
            rules.remove(at: index)
        }
    }

    func removeAllRules() {
        validationErrors.removeAll()
        rules.removeAll()
    }

}

/// Generic class that represents an Eureka row.
class Row<Cell: CellType>: RowOf<Cell.Value>, TypedRowType where Cell: BaseCell {

    /// Responsible for creating the cell for this row.
    var cellProvider = CellProvider<Cell>()

    /// The type of the cell associated to this row.
    let cellType: Cell.Type! = Cell.self

    private var _cell: Cell! {
        didSet {
            RowDefaults.cellSetup["\(type(of: self))"]?(_cell, self)
            (callbackCellSetup as? ((Cell) -> Void))?(_cell)
        }
    }

    /// The cell associated to this row.
    var cell: Cell! {
        return _cell ?? {
            let result = cellProvider.makeCell(style: self.cellStyle)
            result.row = self
            result.setup()
            _cell = result
            return _cell
        }()
    }

    /// The untyped cell associated to this row
    override var baseCell: BaseCell { return cell }

    required init(tag: String?) {
        super.init(tag: tag)
    }

    /**
     Method that reloads the cell
     */
    override open func updateCell() {
        super.updateCell()
        cell.update()
        customUpdateCell()
        RowDefaults.cellUpdate["\(type(of: self))"]?(cell, self)
        callbackCellUpdate?()
    }

    /**
     Method called when the cell belonging to this row was selected. Must call the corresponding method in its cell.
     */
    open override func didSelect() {
        super.didSelect()
        if !isDisabled {
            cell?.didSelect()
        }
        customDidSelect()
        callbackCellOnSelection?()
    }

    /**
     Will be called inside `didSelect` method of the row. Can be used to customize row selection from the definition of the row.
     */
    open func customDidSelect() {}

    /**
     Will be called inside `updateCell` method of the row. Can be used to customize reloading a row from its definition.
     */
    open func customUpdateCell() {}

}

