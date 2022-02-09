//
//  PickerInputRow.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation
import UIKit

// MARK: PickerInputCell

class _PickerInputCell<T> : Cell<T>, CellType, UIPickerViewDataSource, UIPickerViewDelegate where T: Equatable {

    lazy public var picker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    fileprivate var pickerInputRow: _PickerInputRow<T>? { return row as? _PickerInputRow<T> }

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType = .none
        picker.delegate = self
        picker.dataSource = self
    }

    deinit {
        picker.delegate = nil
        picker.dataSource = nil
    }

    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default

        if row.title?.isEmpty == false {
            detailTextLabel?.text = row.displayValueFor?(row.value) ?? (row as? NoValueDisplayTextConformance)?.noValueDisplayText
        } else {
            textLabel?.text = row.displayValueFor?(row.value) ?? (row as? NoValueDisplayTextConformance)?.noValueDisplayText
            detailTextLabel?.text = nil
        }

        if #available(iOS 13.0, *) {
            textLabel?.textColor = row.isDisabled ? .tertiaryLabel : .label
        } else {
            textLabel?.textColor = row.isDisabled ? .gray : .black
        }
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }

        picker.reloadAllComponents()
    }

    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }

    open override var inputView: UIView? {
        return picker
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return canBecomeFirstResponder
    }

    override open var canBecomeFirstResponder: Bool {
        return !row.isDisabled
    }

    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerInputRow?.options.count ?? 0
    }

    open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerInputRow?.displayValueFor?(pickerInputRow?.options[row])
    }

    open func pickerView(_ pickerView: UIPickerView, didSelectRow rowNumber: Int, inComponent component: Int) {
        if let picker = pickerInputRow, picker.options.count > rowNumber {
            picker.value = picker.options[rowNumber]
            update()
        }
    }
}

class PickerInputCell<T>: _PickerInputCell<T> where T: Equatable {

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func update() {
        super.update()
        if let selectedValue = pickerInputRow?.value, let index = pickerInputRow?.options.firstIndex(of: selectedValue) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
    }

}

// MARK: PickerInputRow

class _PickerInputRow<T> : Row<PickerInputCell<T>>, NoValueDisplayTextConformance where T: Equatable {
    open var noValueDisplayText: String? = nil

    open var options = [T]()

    required public init(tag: String?) {
        super.init(tag: tag)

    }
}

/// A generic row where the user can pick an option from a picker view displayed in the keyboard area
final class PickerInputRow<T>: _PickerInputRow<T>, RowType where T: Equatable {

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

