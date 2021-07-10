//
//  LabelRow.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

// MARK: LabelCell

class LabelCellOf<T: Equatable>: Cell<T>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        selectionStyle = .none
    }
}

typealias LabelCell = LabelCellOf<String>

// MARK: LabelRow

class _LabelRow: Row<LabelCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// Simple row that can show title and value but is not editable by user.
final class LabelRow: _LabelRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

