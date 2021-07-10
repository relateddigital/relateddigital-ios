//
//  InlineRowType.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import Foundation

protocol BaseInlineRowType {
    /**
     Method that can be called to expand (open) an inline row
     */
    func expandInlineRow()

    /**
     Method that can be called to collapse (close) an inline row
     */
    func collapseInlineRow()

    /**
     Method that can be called to change the status of an inline row (expanded/collapsed)
     */
    func toggleInlineRow()
}

/**
 *  Protocol that every inline row type has to conform to.
 */
protocol InlineRowType: TypedRowType, BaseInlineRowType {

    associatedtype InlineRow: BaseRow, RowType

    /**
     This function is responsible for setting up an inline row before it is first shown.
     */
    func setupInlineRow(_ inlineRow: InlineRow)
}

extension InlineRowType where Self: BaseRow, Self.Cell.Value ==  Self.InlineRow.Cell.Value {

    /// The row that will be inserted below after the current one when it is selected.
    var inlineRow: Self.InlineRow? { return _inlineRow as? Self.InlineRow }

    /**
     Method that can be called to expand (open) an inline row.
     */
    func expandInlineRow() {
        if let _ = inlineRow { return }
        if var section = section, let form = section.form {
            let inline = InlineRow.init { _ in }
            inline.value = value
            inline.onChange { [weak self] in
                self?.value = $0.value
                self?.updateCell()
            }
            setupInlineRow(inline)
            if (form.inlineRowHideOptions ?? Form.defaultInlineRowHideOptions).contains(.AnotherInlineRowIsShown) {
                for row in form.allRows {
                    if let inlineRow = row as? BaseInlineRowType {
                        inlineRow.collapseInlineRow()
                    }
                }
            }
            if let onExpandInlineRowCallback = onExpandInlineRowCallback {
                onExpandInlineRowCallback(cell, self, inline)
            }
            if let indexPath = indexPath {
                _inlineRow = inline
                section.insert(inline, at: indexPath.row + 1)
                cell.formViewController()?.makeRowVisible(inline, destinationScrollPosition: destinationScrollPosition)
            }
        }
    }

    /**
     Method that can be called to collapse (close) an inline row.
     */
    func collapseInlineRow() {
        if let selectedRowPath = indexPath, let inlineRow = _inlineRow {
            if let onCollapseInlineRowCallback = onCollapseInlineRowCallback {
                onCollapseInlineRowCallback(cell, self, inlineRow as! InlineRow)
            }
            _inlineRow = nil
            section?.remove(at: selectedRowPath.row + 1)
        }
    }

    /**
     Method that can be called to change the status of an inline row (expanded/collapsed).
     */
    func toggleInlineRow() {
        if let _ = inlineRow {
            collapseInlineRow()
        } else {
            expandInlineRow()
        }
    }

    /**
     Sets a block to be executed when a row is expanded.
     */
    @discardableResult
    func onExpandInlineRow(_ callback: @escaping (Cell, Self, InlineRow) -> Void) -> Self {
        callbackOnExpandInlineRow = callback
        return self
    }

    /**
     Sets a block to be executed when a row is collapsed.
     */
    @discardableResult
    func onCollapseInlineRow(_ callback: @escaping (Cell, Self, InlineRow) -> Void) -> Self {
        callbackOnCollapseInlineRow = callback
        return self
    }

    /// Returns the block that will be executed when this row expands
    var onCollapseInlineRowCallback: ((Cell, Self, InlineRow) -> Void)? {
        return callbackOnCollapseInlineRow as! ((Cell, Self, InlineRow) -> Void)?
    }

    /// Returns the block that will be executed when this row collapses
    var onExpandInlineRowCallback: ((Cell, Self, InlineRow) -> Void)? {
        return callbackOnExpandInlineRow as! ((Cell, Self, InlineRow) -> Void)?
    }

    var isExpanded: Bool { return _inlineRow != nil }
    var isCollapsed: Bool { return !isExpanded }
}

