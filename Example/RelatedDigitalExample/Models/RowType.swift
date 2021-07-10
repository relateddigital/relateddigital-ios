//
//  RowType.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

protocol Disableable: Taggable {
    var isDisabled: Bool { get }
}

protocol Hidable: Taggable {
    func evaluateHidden()
    var isHidden: Bool { get }
}

protocol KeyboardReturnHandler: BaseRowType {
    var keyboardReturnType: KeyboardReturnTypeConfiguration? { get set }
}

protocol Taggable: AnyObject {
    var tag: String? { get set }
}

protocol BaseRowType: Taggable {

    /// The cell associated to this row.
    var baseCell: BaseCell! { get }

    /// The section to which this row belongs.
    var section: Section? { get }

    /// Parameter used when creating the cell for this row.
    var cellStyle: UITableViewCell.CellStyle { get set }

    /// The title will be displayed in the textLabel of the row.
    var title: String? { get set }

    /**
     Method that should re-display the cell
     */
    func updateCell()

    /**
     Method called when the cell belonging to this row was selected. Must call the corresponding method in its cell.
     */
    func didSelect()

    /**
     Typically we don't need to explicitly call this method since it is called by Eureka framework. It will validates the row if you invoke it.
     */
    func validate(quietly: Bool) -> [ValidationError]
}

protocol TypedRowType: BaseRowType {

    associatedtype Cell: BaseCell, TypedCellType

    /// The typed cell associated to this row.
    var cell: Cell! { get }

    /// The typed value this row stores.
    var value: Cell.Value? { get set }

    func add<Rule: RuleType>(rule: Rule) where Rule.RowValueType == Cell.Value
    func remove(ruleWithIdentifier: String)
}

/**
 *  Protocol that every row type has to conform to.
 */
protocol RowType: TypedRowType {
    init(_ tag: String?, _ initializer: (Self) -> Void)
}

extension RowType where Self: BaseRow {

    /**
     Default initializer for a row
     */
    init(_ tag: String? = nil, _ initializer: (Self) -> Void = { _ in }) {
        self.init(tag: tag)
        RowDefaults.rowInitialization["\(type(of: self))"]?(self)
        initializer(self)
    }
}

extension RowType where Self: BaseRow {

    /// The default block executed when the cell is updated. Applies to every row of this type.
    static var defaultCellUpdate: ((Cell, Self) -> Void)? {
        set {
            if let newValue = newValue {
                let wrapper: (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                    newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.cellUpdate["\(self)"] = wrapper
                RowDefaults.rawCellUpdate["\(self)"] = newValue
            } else {
                RowDefaults.cellUpdate["\(self)"] = nil
                RowDefaults.rawCellUpdate["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawCellUpdate["\(self)"] as? ((Cell, Self) -> Void) }
    }

    /// The default block executed when the cell is created. Applies to every row of this type.
    static var defaultCellSetup: ((Cell, Self) -> Void)? {
        set {
            if let newValue = newValue {
                let wrapper: (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                    newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.cellSetup["\(self)"] = wrapper
                RowDefaults.rawCellSetup["\(self)"] = newValue
            } else {
                RowDefaults.cellSetup["\(self)"] = nil
                RowDefaults.rawCellSetup["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawCellSetup["\(self)"] as? ((Cell, Self) -> Void) }
    }

    /// The default block executed when the cell becomes first responder. Applies to every row of this type.
    static var defaultOnCellHighlightChanged: ((Cell, Self) -> Void)? {
        set {
            if let newValue = newValue {
                let wrapper: (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                    newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.onCellHighlightChanged ["\(self)"] = wrapper
                RowDefaults.rawOnCellHighlightChanged["\(self)"] = newValue
            } else {
                RowDefaults.onCellHighlightChanged["\(self)"] = nil
                RowDefaults.rawOnCellHighlightChanged["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawOnCellHighlightChanged["\(self)"] as? ((Cell, Self) -> Void) }
    }

    /// The default block executed to initialize a row. Applies to every row of this type.
    static var defaultRowInitializer: ((Self) -> Void)? {
        set {
            if let newValue = newValue {
                let wrapper: (BaseRow) -> Void = { (baseRow: BaseRow) in
                    newValue(baseRow as! Self)
                }
                RowDefaults.rowInitialization["\(self)"] = wrapper
                RowDefaults.rawRowInitialization["\(self)"] = newValue
            } else {
                RowDefaults.rowInitialization["\(self)"] = nil
                RowDefaults.rawRowInitialization["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawRowInitialization["\(self)"] as? ((Self) -> Void) }
    }

    /// The default block executed to initialize a row. Applies to every row of this type.
    static var defaultOnRowValidationChanged: ((Cell, Self) -> Void)? {
        set {
            if let newValue = newValue {
                let wrapper: (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                    newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.onRowValidationChanged["\(self)"] = wrapper
                RowDefaults.rawOnRowValidationChanged["\(self)"] = newValue
            } else {
                RowDefaults.onRowValidationChanged["\(self)"] = nil
                RowDefaults.rawOnRowValidationChanged["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawOnRowValidationChanged["\(self)"] as? ((Cell, Self) -> Void) }
    }

    /**
     Sets a block to be called when the value of this row changes.

     - returns: this row
     */
    @discardableResult
    func onChange(_ callback: @escaping (Self) -> Void) -> Self {
        callbackOnChange = { [weak self] in callback(self!) }
        return self
    }

    /**
     Sets a block to be called when the cell corresponding to this row is refreshed.

     - returns: this row
     */
    @discardableResult
    func cellUpdate(_ callback: @escaping ((_ cell: Cell, _ row: Self) -> Void)) -> Self {
        callbackCellUpdate = { [weak self] in  callback(self!.cell, self!) }
        return self
    }

    /**
     Sets a block to be called when the cell corresponding to this row is created.

     - returns: this row
     */
    @discardableResult
    func cellSetup(_ callback: @escaping ((_ cell: Cell, _ row: Self) -> Void)) -> Self {
        callbackCellSetup = { [weak self] (cell: Cell) in  callback(cell, self!) }
        return self
    }

    /**
     Sets a block to be called when the cell corresponding to this row is selected.

     - returns: this row
     */
    @discardableResult
    func onCellSelection(_ callback: @escaping ((_ cell: Cell, _ row: Self) -> Void)) -> Self {
        callbackCellOnSelection = { [weak self] in  callback(self!.cell, self!) }
        return self
    }

    /**
     Sets a block to be called when the cell corresponding to this row becomes or resigns the first responder.

     - returns: this row
     */
    @discardableResult
    func onCellHighlightChanged(_ callback: @escaping (_ cell: Cell, _ row: Self) -> Void) -> Self {
        callbackOnCellHighlightChanged = { [weak self] in callback(self!.cell, self!) }
        return self
    }

    @discardableResult
    func onRowValidationChanged(_ callback: @escaping (_ cell: Cell, _ row: Self) -> Void) -> Self {
        callbackOnRowValidationChanged = { [weak self] in  callback(self!.cell, self!) }
        return self
    }
}

