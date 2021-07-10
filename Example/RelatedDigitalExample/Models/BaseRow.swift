//
//  BaseRow.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

class BaseRow: BaseRowType {

    var callbackOnChange: (() -> Void)?
    var callbackCellUpdate: (() -> Void)?
    var callbackCellSetup: Any?
    var callbackCellOnSelection: (() -> Void)?
    var callbackOnExpandInlineRow: Any?
    var callbackOnCollapseInlineRow: Any?
    var callbackOnCellHighlightChanged: (() -> Void)?
    var callbackOnRowValidationChanged: (() -> Void)?
    var _inlineRow: BaseRow?

    var _cachedOptionsData: Any?

    var validationOptions: ValidationOptions = .validatesOnBlur
    // validation state
    var validationErrors = [ValidationError]() {
        didSet {
            guard validationErrors != oldValue else { return }
            RowDefaults.onRowValidationChanged["\(type(of: self))"]?(baseCell, self)
            callbackOnRowValidationChanged?()
            updateCell()
        }
    }

    var wasBlurred = false
    var wasChanged = false

    var isValid: Bool { return validationErrors.isEmpty }
    var isHighlighted: Bool = false

    /// The title will be displayed in the textLabel of the row.
    var title: String?

    /// Parameter used when creating the cell for this row.
    var cellStyle = UITableViewCell.CellStyle.value1

    /// String that uniquely identifies a row. Must be unique among rows and sections.
    var tag: String?

    /// The untyped cell associated to this row.
    var baseCell: BaseCell! { return nil }

    /// The untyped value of this row.
    var baseValue: Any? {
        set {}
        get { return nil }
    }

    func validate(quietly: Bool = false) -> [ValidationError] {
        return []
    }

    // Reset validation
    func cleanValidationErrors() {
        validationErrors = []
    }

    static var estimatedRowHeight: CGFloat = 44.0

    /// Condition that determines if the row should be disabled or not.
    var disabled: Condition? {
        willSet { removeFromDisabledRowObservers() }
        didSet { addToDisabledRowObservers() }
    }

    /// Condition that determines if the row should be hidden or not.
    var hidden: Condition? {
        willSet { removeFromHiddenRowObservers() }
        didSet { addToHiddenRowObservers() }
    }

    /// Returns if this row is currently disabled or not
    var isDisabled: Bool { return disabledCache }

    /// Returns if this row is currently hidden or not
    var isHidden: Bool { return hiddenCache }

    /// The section to which this row belongs.
    weak var section: Section?
    
    lazy var trailingSwipe = {[unowned self] in SwipeConfiguration(self)}()
    
    //needs the accessor because if marked directly this throws "Stored properties cannot be marked potentially unavailable with '@available'"
    private lazy var _leadingSwipe = {[unowned self] in SwipeConfiguration(self)}()

    @available(iOS 11,*)
    var leadingSwipe: SwipeConfiguration{
        get { return self._leadingSwipe }
        set { self._leadingSwipe = newValue }
    }
    
    required init(tag: String? = nil) {
        self.tag = tag
    }

    /**
     Method that reloads the cell
     */
    func updateCell() {}

    /**
     Method called when the cell belonging to this row was selected. Must call the corresponding method in its cell.
     */
    func didSelect() {}

    func prepare(for segue: UIStoryboardSegue) {}

    /**
     Helps to pick destination part of the cell after scrolling
     */
    var destinationScrollPosition: UITableView.ScrollPosition? = UITableView.ScrollPosition.bottom

    /**
     Returns the IndexPath where this row is in the current form.
     */
    final var indexPath: IndexPath? {
        guard let sectionIndex = section?.index, let rowIndex = section?.firstIndex(of: self) else { return nil }
        return IndexPath(row: rowIndex, section: sectionIndex)
    }

    var hiddenCache = false
    var disabledCache = false {
        willSet {
            if newValue && !disabledCache {
                baseCell.cellResignFirstResponder()
            }
        }
    }
}

extension BaseRow {

    /**
     Evaluates if the row should be hidden or not and updates the form accordingly
     */
    final func evaluateHidden() {
        guard let h = hidden, let form = section?.form else { return }
        switch h {
        case .function(_, let callback):
            hiddenCache = callback(form)
        case .predicate(let predicate):
            hiddenCache = predicate.evaluate(with: self, substitutionVariables: form.dictionaryValuesToEvaluatePredicate())
        }
        if hiddenCache {
            section?.hide(row: self)
        } else {
            section?.show(row: self)
        }
    }

    /**
     Evaluates if the row should be disabled or not and updates it accordingly
     */
    final func evaluateDisabled() {
        guard let d = disabled, let form = section?.form else { return }
        switch d {
        case .function(_, let callback):
            disabledCache = callback(form)
        case .predicate(let predicate):
            disabledCache = predicate.evaluate(with: self, substitutionVariables: form.dictionaryValuesToEvaluatePredicate())
        }
        updateCell()
    }

    final func wasAddedTo(section: Section) {
        self.section = section
        if let t = tag {
            assert(section.form?.rowsByTag[t] == nil, "Duplicate tag \(t)")
            self.section?.form?.rowsByTag[t] = self
            self.section?.form?.tagToValues[t] = baseValue != nil ? baseValue! : NSNull()
        }
        addToRowObservers()
        evaluateHidden()
        evaluateDisabled()
    }

    final func addToHiddenRowObservers() {
        guard let h = hidden else { return }
        switch h {
        case .function(let tags, _):
            section?.form?.addRowObservers(to: self, rowTags: tags, type: .hidden)
        case .predicate(let predicate):
            section?.form?.addRowObservers(to: self, rowTags: predicate.predicateVars, type: .hidden)
        }
    }

    final func addToDisabledRowObservers() {
        guard let d = disabled else { return }
        switch d {
        case .function(let tags, _):
            section?.form?.addRowObservers(to: self, rowTags: tags, type: .disabled)
        case .predicate(let predicate):
            section?.form?.addRowObservers(to: self, rowTags: predicate.predicateVars, type: .disabled)
        }
    }

    final func addToRowObservers() {
        addToHiddenRowObservers()
        addToDisabledRowObservers()
    }

    final func willBeRemovedFromForm() {
        (self as? BaseInlineRowType)?.collapseInlineRow()
        if let t = tag {
            section?.form?.rowsByTag[t] = nil
            section?.form?.tagToValues[t] = nil
        }
        removeFromRowObservers()
    }

    final func willBeRemovedFromSection() {
        willBeRemovedFromForm()
        section = nil
    }

    final func removeFromHiddenRowObservers() {
        guard let h = hidden else { return }
        switch h {
        case .function(let tags, _):
            section?.form?.removeRowObservers(from: self, rowTags: tags, type: .hidden)
        case .predicate(let predicate):
            section?.form?.removeRowObservers(from: self, rowTags: predicate.predicateVars, type: .hidden)
        }
    }

    final func removeFromDisabledRowObservers() {
        guard let d = disabled else { return }
        switch d {
        case .function(let tags, _):
            section?.form?.removeRowObservers(from: self, rowTags: tags, type: .disabled)
        case .predicate(let predicate):
            section?.form?.removeRowObservers(from: self, rowTags: predicate.predicateVars, type: .disabled)
        }
    }

    final func removeFromRowObservers() {
        removeFromHiddenRowObservers()
        removeFromDisabledRowObservers()
    }
}

extension BaseRow: Equatable, Hidable, Disableable {}

extension BaseRow {

    func reload(with rowAnimation: UITableView.RowAnimation = .none) {
        guard let tableView = baseCell?.formViewController()?.tableView ?? (section?.form?.delegate as? FormViewController)?.tableView, let indexPath = indexPath else { return }
        tableView.reloadRows(at: [indexPath], with: rowAnimation)
    }

    func deselect(animated: Bool = true) {
        guard let indexPath = indexPath,
            let tableView = baseCell?.formViewController()?.tableView ?? (section?.form?.delegate as? FormViewController)?.tableView  else { return }
        tableView.deselectRow(at: indexPath, animated: animated)
    }

    func select(animated: Bool = false, scrollPosition: UITableView.ScrollPosition = .none) {
        guard let indexPath = indexPath,
            let tableView = baseCell?.formViewController()?.tableView ?? (section?.form?.delegate as? FormViewController)?.tableView  else { return }
        tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }
}

func == (lhs: BaseRow, rhs: BaseRow) -> Bool {
    return lhs === rhs
}
