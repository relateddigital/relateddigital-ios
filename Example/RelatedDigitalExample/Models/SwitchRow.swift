//
//  SwitchRow.swift
//  RelatedDigitalExample
//
//  Created by Umut Can Alparslan on 8.02.2022.
//

import Foundation
import UIKit

// MARK: SwitchCell

class SwitchCell: Cell<Bool>, CellType {

    @IBOutlet public weak var switchControl: UISwitch!

    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let switchC = UISwitch()
        switchControl = switchC
        accessoryView = switchControl
        editingAccessoryView = accessoryView
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        selectionStyle = .none
        switchControl.addTarget(self, action: #selector(SwitchCell.valueChanged), for: .valueChanged)
    }

    deinit {
        switchControl?.removeTarget(self, action: nil, for: .allEvents)
    }

    open override func update() {
        super.update()
        switchControl.isOn = row.value ?? false
        switchControl.isEnabled = !row.isDisabled
    }

    @objc (valueDidChange) func valueChanged() {
        row.value = switchControl?.isOn ?? false
    }
}

// MARK: SwitchRow

class _SwitchRow: Row<SwitchCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

/// Boolean row that has a UISwitch as accessoryType
final class SwitchRow: _SwitchRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

