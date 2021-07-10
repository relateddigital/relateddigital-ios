//
//  ButtonRow.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

// MARK: ButtonCell

class ButtonCellOf<T: Equatable>: Cell<T>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        accessoryType = .none
        editingAccessoryType = accessoryType
        textLabel?.textAlignment = .center
        textLabel?.textColor = tintColor.withAlphaComponent(row.isDisabled ? 0.3 : 1.0)
    }

    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }
}

typealias ButtonCell = ButtonCellOf<String>

// MARK: ButtonRow

class _ButtonRowOf<T: Equatable> : Row<ButtonCellOf<T>> {
    var presentationMode: PresentationMode<UIViewController>?

    required init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        cellStyle = .default
    }

    override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.makeController() {
                    presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
                } else {
                    presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
                }
            }
        }
    }

    override func customUpdateCell() {
        super.customUpdateCell()
        let leftAligmnment = presentationMode != nil
        cell.textLabel?.textAlignment = leftAligmnment ? .left : .center
        cell.accessoryType = !leftAligmnment || isDisabled ? .none : .disclosureIndicator
        cell.editingAccessoryType = cell.accessoryType
        cell.textLabel?.textColor = !leftAligmnment ? cell.tintColor.withAlphaComponent(isDisabled ? 0.3 : 1.0) : nil
    }

    override func prepare(for segue: UIStoryboardSegue) {
        super.prepare(for: segue)
        (segue.destination as? RowControllerType)?.onDismissCallback = presentationMode?.onDismissCallback
    }
}

/// A generic row with a button. The action of this button can be anything but normally will push a new view controller
final class ButtonRowOf<T: Equatable> : _ButtonRowOf<T>, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row with a button and String value. The action of this button can be anything but normally will push a new view controller
typealias ButtonRow = ButtonRowOf<String>

