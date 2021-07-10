//
//  Cell.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

/// Base class for the Eureka cells
class BaseCell: UITableViewCell, BaseCellType {

    /// Untyped row associated to this cell.
    var baseRow: BaseRow! { return nil }

    /// Block that returns the height for this cell.
    var height: (() -> CGFloat)?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    /**
     Function that returns the FormViewController this cell belongs to.
     */
    func formViewController() -> FormViewController? {
        var responder: AnyObject? = self
        while responder != nil {
            if let formVC = responder as? FormViewController {
              return formVC
            }
            responder = responder?.next
        }
        return nil
    }

    open func setup() {}
    open func update() {}

    open func didSelect() {}

    /**
     If the cell can become first responder. By default returns false
     */
    open func cellCanBecomeFirstResponder() -> Bool {
        return false
    }

    /**
     Called when the cell becomes first responder
     */
    @discardableResult
    open func cellBecomeFirstResponder(withDirection: Direction = .down) -> Bool {
        return becomeFirstResponder()
    }

    /**
     Called when the cell resigns first responder
     */
    @discardableResult
    open func cellResignFirstResponder() -> Bool {
        return resignFirstResponder()
    }
}

/// Generic class that represents the Eureka cells.
class Cell<T>: BaseCell, TypedCellType where T: Equatable {

    typealias Value = T

    /// The row associated to this cell
    weak var row: RowOf<T>!

    private var updatingCellForTintColorDidChange = false

    /// Returns the navigationAccessoryView if it is defined or calls super if not.
    override open var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryView(for: row) {
            return v
        }
        return super.inputAccessoryView
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    /**
     Function responsible for setting up the cell at creation time.
     */
    open override func setup() {
        super.setup()
    }

    /**
     Function responsible for updating the cell each time it is reloaded.
     */
    open override func update() {
        super.update()
        textLabel?.text = row.title
        if #available(iOS 13.0, *) {
            textLabel?.textColor = row.isDisabled ? .tertiaryLabel : .label
        } else {
            textLabel?.textColor = row.isDisabled ? .gray : .black
        }
        detailTextLabel?.text = row.displayValueFor?(row.value) ?? (row as? NoValueDisplayTextConformance)?.noValueDisplayText
    }

    /**
     Called when the cell was selected.
     */
    open override func didSelect() {}

    override open var canBecomeFirstResponder: Bool {
        return false
    }

    open override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            // TODO:
            //formViewController()?.beginEditing(of: self)
        }
        return result
    }

    open override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            // TODO:
            //formViewController()?.endEditing(of: self)
        }
        return result
    }

    open override func tintColorDidChange() {
        super.tintColorDidChange()

        /* Protection from infinite recursion in case an update method changes the tintColor */
        if !updatingCellForTintColorDidChange && row != nil {
            updatingCellForTintColorDidChange = true
            row.updateCell()
            updatingCellForTintColorDidChange = false
        }
    }

    /// The untyped row associated to this cell.
    override var baseRow: BaseRow! { return row }
}

