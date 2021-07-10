//
//  FormViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

/// View controller that shows a form.
@objc(EurekaFormViewController)
class FormViewController: UIViewController, FormViewControllerProtocol, FormDelegate {

    @IBOutlet var tableView: UITableView!

    private lazy var _form: Form = { [weak self] in
        let form = Form()
        form.delegate = self
        return form
        }()

    var form: Form {
        get { return _form }
        set {
            guard form !== newValue else { return }
            _form.delegate = nil
            tableView?.endEditing(false)
            _form = newValue
            _form.delegate = self
            if isViewLoaded {
                tableView?.reloadData()
            }
        }
    }

    /// Extra space to leave between between the row in focus and the keyboard
    var rowKeyboardSpacing: CGFloat = 0

    /// Enables animated scrolling on row navigation
    var animateScroll = false
    
    /// The default scroll position on the focussed cell when keyboard appears
    var defaultScrollPosition = UITableView.ScrollPosition.none

    /// Accessory view that is responsible for the navigation between rows
    private var navigationAccessoryView: (UIView & NavigationAccessory)!

    /// Custom Accesory View to be used as a replacement
    var customNavigationAccessoryView: (UIView & NavigationAccessory)? {
        return nil
    }

    /// Defines the behaviour of the navigation between rows
    var navigationOptions: RowNavigationOptions?
    var tableViewStyle: UITableView.Style = .grouped

    init(style: UITableView.Style) {
        super.init(nibName: nil, bundle: nil)
        tableViewStyle = style
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationAccessoryView = customNavigationAccessoryView ?? NavigationAccessoryView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0))
        navigationAccessoryView.autoresizingMask = .flexibleWidth

        if tableView == nil {
            tableView = UITableView(frame: view.bounds, style: tableViewStyle)
            tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        if tableView.superview == nil {
            view.addSubview(tableView)
        }
        if tableView.delegate == nil {
            tableView.delegate = self
        }
        if tableView.dataSource == nil {
            tableView.dataSource = self
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = BaseRow.estimatedRowHeight
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateTableView = true
        let selectedIndexPaths = tableView.indexPathsForSelectedRows ?? []
        if !selectedIndexPaths.isEmpty {
            if #available(iOS 13.0, *) {
                if tableView.window != nil {
                    tableView.reloadRows(at: selectedIndexPaths, with: .none)
                }
            } else {
                tableView.reloadRows(at: selectedIndexPaths, with: .none)
            }
        }
        selectedIndexPaths.forEach {
            tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
        }

        let deselectionAnimation = { [weak self] (context: UIViewControllerTransitionCoordinatorContext) in
            selectedIndexPaths.forEach {
                self?.tableView.deselectRow(at: $0, animated: context.isAnimated)
            }
        }

        let reselection = { [weak self] (context: UIViewControllerTransitionCoordinatorContext) in
            if context.isCancelled {
                selectedIndexPaths.forEach {
                    self?.tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
                }
            }
        }

        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: deselectionAnimation, completion: reselection)
        } else {
            selectedIndexPaths.forEach {
                tableView.deselectRow(at: $0, animated: false)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(FormViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FormViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        if form.containsMultivaluedSection && (isBeingPresented || isMovingToParent) {
            tableView.setEditing(true, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let baseRow = sender as? BaseRow
        baseRow?.prepare(for: segue)
    }

    /**
     Returns the navigation accessory view if it is enabled. Returns nil otherwise.
     */
    func inputAccessoryView(for row: BaseRow) -> UIView? {
        let options = navigationOptions ?? Form.defaultNavigationOptions
        guard options.contains(.Enabled) else { return nil }
        guard row.baseCell.cellCanBecomeFirstResponder() else { return nil}
        navigationAccessoryView.previousEnabled = nextRow(for: row, withDirection: .up) != nil
        navigationAccessoryView.doneClosure = { [weak self] in
            self?.navigationDone()
        }
        navigationAccessoryView.previousClosure = { [weak self] in
            self?.navigationPrevious()
        }
        navigationAccessoryView.nextClosure = { [weak self] in
            self?.navigationNext()
        }
        navigationAccessoryView.nextEnabled = nextRow(for: row, withDirection: .down) != nil
        return navigationAccessoryView
    }

    // MARK: FormViewControllerProtocol

    /**
    Called when a cell becomes first responder
    */
    final func beginEditing<T>(of cell: Cell<T>) {
        cell.row.isHighlighted = true
        cell.row.updateCell()
        RowDefaults.onCellHighlightChanged["\(type(of: cell.row!))"]?(cell, cell.row)
        cell.row.callbackOnCellHighlightChanged?()
        guard let _ = tableView, (form.inlineRowHideOptions ?? Form.defaultInlineRowHideOptions).contains(.FirstResponderChanges) else { return }
        let row = cell.baseRow
        let inlineRow = row?._inlineRow
        for row in form.allRows.filter({ $0 !== row && $0 !== inlineRow && $0._inlineRow != nil }) {
            if let inlineRow = row as? BaseInlineRowType {
                inlineRow.collapseInlineRow()
            }
        }
    }

    /**
     Called when a cell resigns first responder
     */
    final func endEditing<T>(of cell: Cell<T>) {
        cell.row.isHighlighted = false
        cell.row.wasBlurred = true
        RowDefaults.onCellHighlightChanged["\(type(of: cell.row!))"]?(cell, cell.row)
        cell.row.callbackOnCellHighlightChanged?()
        if cell.row.validationOptions.contains(.validatesOnBlur) || (cell.row.wasChanged && cell.row.validationOptions.contains(.validatesOnChangeAfterBlurred)) {
            cell.row.validate()
        }
        cell.row.updateCell()
    }

    /**
     Returns the animation for the insertion of the given rows.
     */
    func insertAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation {
        return .fade
    }

    /**
     Returns the animation for the deletion of the given rows.
     */
    func deleteAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation {
        return .fade
    }

    /**
     Returns the animation for the reloading of the given rows.
     */
    func reloadAnimation(oldRows: [BaseRow], newRows: [BaseRow]) -> UITableView.RowAnimation {
        return .automatic
    }

    /**
     Returns the animation for the insertion of the given sections.
     */
    func insertAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }

    /**
     Returns the animation for the deletion of the given sections.
     */
    func deleteAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }

    /**
     Returns the animation for the reloading of the given sections.
     */
    func reloadAnimation(oldSections: [Section], newSections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }

    // MARK: TextField and TextView Delegate

    func textInputShouldBeginEditing<T>(_ textInput: UITextInput, cell: Cell<T>) -> Bool {
        return true
    }

    func textInputDidBeginEditing<T>(_ textInput: UITextInput, cell: Cell<T>) {
        if let row = cell.row as? KeyboardReturnHandler {
            let next = nextRow(for: cell.row, withDirection: .down)
            if let textField = textInput as? UITextField {
                textField.returnKeyType = next != nil ? (row.keyboardReturnType?.nextKeyboardType ??
                    (form.keyboardReturnType?.nextKeyboardType ?? Form.defaultKeyboardReturnType.nextKeyboardType )) :
                    (row.keyboardReturnType?.defaultKeyboardType ?? (form.keyboardReturnType?.defaultKeyboardType ??
                        Form.defaultKeyboardReturnType.defaultKeyboardType))
            } else if let textView = textInput as? UITextView {
                textView.returnKeyType = next != nil ? (row.keyboardReturnType?.nextKeyboardType ??
                    (form.keyboardReturnType?.nextKeyboardType ?? Form.defaultKeyboardReturnType.nextKeyboardType )) :
                    (row.keyboardReturnType?.defaultKeyboardType ?? (form.keyboardReturnType?.defaultKeyboardType ??
                        Form.defaultKeyboardReturnType.defaultKeyboardType))
            }
        }
    }

    func textInputShouldEndEditing<T>(_ textInput: UITextInput, cell: Cell<T>) -> Bool {
        return true
    }

    func textInputDidEndEditing<T>(_ textInput: UITextInput, cell: Cell<T>) {

    }

    func textInput<T>(_ textInput: UITextInput, shouldChangeCharactersInRange range: NSRange, replacementString string: String, cell: Cell<T>) -> Bool {
        return true
    }

    func textInputShouldClear<T>(_ textInput: UITextInput, cell: Cell<T>) -> Bool {
        return true
    }

    func textInputShouldReturn<T>(_ textInput: UITextInput, cell: Cell<T>) -> Bool {
        if let nextRow = nextRow(for: cell.row, withDirection: .down) {
            if nextRow.baseCell.cellCanBecomeFirstResponder() {
                nextRow.baseCell.cellBecomeFirstResponder()
                return true
            }
        }
        tableView?.endEditing(true)
        return true
    }

    // MARK: FormDelegate

    func valueHasBeenChanged(for: BaseRow, oldValue: Any?, newValue: Any?) {}

    // MARK: UITableViewDelegate

    @objc func tableView(_ tableView: UITableView, willBeginReorderingRowAtIndexPath indexPath: IndexPath) {
        // end editing if inline cell is first responder
        let row = form[indexPath]
        if let inlineRow = row as? BaseInlineRowType, row._inlineRow != nil {
            inlineRow.collapseInlineRow()
        }
    }

    // MARK: FormDelegate

    func sectionsHaveBeenAdded(_ sections: [Section], at indexes: IndexSet) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.insertSections(indexes, with: insertAnimation(forSections: sections))
        tableView?.endUpdates()
    }

    func sectionsHaveBeenRemoved(_ sections: [Section], at indexes: IndexSet) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.deleteSections(indexes, with: deleteAnimation(forSections: sections))
        tableView?.endUpdates()
    }

    func sectionsHaveBeenReplaced(oldSections: [Section], newSections: [Section], at indexes: IndexSet) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.reloadSections(indexes, with: reloadAnimation(oldSections: oldSections, newSections: newSections))
        tableView?.endUpdates()
    }

    func rowsHaveBeenAdded(_ rows: [BaseRow], at indexes: [IndexPath]) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.insertRows(at: indexes, with: insertAnimation(forRows: rows))
        tableView?.endUpdates()
    }

    func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.deleteRows(at: indexes, with: deleteAnimation(forRows: rows))
        tableView?.endUpdates()
    }

    func rowsHaveBeenReplaced(oldRows: [BaseRow], newRows: [BaseRow], at indexes: [IndexPath]) {
        guard animateTableView else { return }
        tableView?.beginUpdates()
        tableView?.reloadRows(at: indexes, with: reloadAnimation(oldRows: oldRows, newRows: newRows))
        tableView?.endUpdates()
    }

    // MARK: Private

    var oldBottomInset: CGFloat?
    var animateTableView = false

    /** Calculates the height needed for a header or footer. */
    fileprivate func height(specifiedHeight: (() -> CGFloat)?, sectionView: UIView?, sectionTitle: String?) -> CGFloat {
        if let height = specifiedHeight {
            return height()
        }

        if let sectionView = sectionView {
            let height = sectionView.bounds.height

            if height == 0 {
                return UITableView.automaticDimension
            }

            return height
        }

        if let sectionTitle = sectionTitle,
            sectionTitle != "" {
            return UITableView.automaticDimension
        }

        // Fix for iOS 11+. By returning 0, we ensure that no section header or
        // footer is shown when self-sizing is enabled (i.e. when
        // tableView.estimatedSectionHeaderHeight or tableView.estimatedSectionFooterHeight
        // == UITableView.automaticDimension).
        if tableView.style == .plain {
            return 0
        }

        return UITableView.automaticDimension
    }
}

extension FormViewController : UITableViewDelegate {

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView == self.tableView else { return }
        let row = form[indexPath]
        // row.baseCell.cellBecomeFirstResponder() may be cause InlineRow collapsed then section count will be changed. Use orignal indexPath will out of  section's bounds.
        if !row.baseCell.cellCanBecomeFirstResponder() || !row.baseCell.cellBecomeFirstResponder() {
            self.tableView?.endEditing(true)
        }
        row.didSelect()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView == self.tableView else { return tableView.rowHeight }
        let row = form[indexPath.section][indexPath.row]
        return row.baseCell.height?() ?? tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView == self.tableView else { return tableView.estimatedRowHeight }
        let row = form[indexPath.section][indexPath.row]
        return row.baseCell.height?() ?? tableView.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return form[section].header?.viewForSection(form[section], type: .header)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return form[section].footer?.viewForSection(form[section], type:.footer)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return height(specifiedHeight: form[section].header?.height,
                      sectionView: self.tableView(tableView, viewForHeaderInSection: section),
                      sectionTitle: self.tableView(tableView, titleForHeaderInSection: section))
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return height(specifiedHeight: form[section].footer?.height,
                      sectionView: self.tableView(tableView, viewForFooterInSection: section),
                      sectionTitle: self.tableView(tableView, titleForFooterInSection: section))
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let row = form[indexPath]
        guard !row.isDisabled else { return false }
        if row.trailingSwipe.actions.count > 0 { return true }
        if #available(iOS 11,*), row.leadingSwipe.actions.count > 0 { return true }
        guard let section = form[indexPath.section] as? BaseMultivaluedSection else { return false }
        guard !(indexPath.row == section.count - 1 && section.multivaluedOptions.contains(.Insert) && section.showInsertIconInAddButton) else {
            return true
        }
        if indexPath.row > 0 && section[indexPath.row - 1] is BaseInlineRowType && section[indexPath.row - 1]._inlineRow != nil {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let row = form[indexPath]
            let section = row.section!
            if let _ = row.baseCell.findFirstResponder() {
                tableView.endEditing(true)
            }
            section.remove(at: indexPath.row)
        } else if editingStyle == .insert {
            guard var section = form[indexPath.section] as? BaseMultivaluedSection else { return }
            guard let multivaluedRowToInsertAt = section.multivaluedRowToInsertAt else {
                fatalError("Multivalued section multivaluedRowToInsertAt property must be set up")
            }
            let newRow = multivaluedRowToInsertAt(max(0, section.count - 1))
            section.insert(newRow, at: max(0, section.count - 1))
            DispatchQueue.main.async {
                tableView.isEditing = !tableView.isEditing
                tableView.isEditing = !tableView.isEditing
            }
            tableView.scrollToRow(at: IndexPath(row: section.count - 1, section: indexPath.section), at: .bottom, animated: true)
            if newRow.baseCell.cellCanBecomeFirstResponder() {
                newRow.baseCell.cellBecomeFirstResponder()
            } else if let inlineRow = newRow as? BaseInlineRowType {
                inlineRow.expandInlineRow()
            }
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let section = form[indexPath.section] as? BaseMultivaluedSection, section.multivaluedOptions.contains(.Reorder) && section.count > 1 else {
            return false
        }
        if section.multivaluedOptions.contains(.Insert) && (section.count <= 2 || indexPath.row == (section.count - 1)) {
            return false
        }
        if indexPath.row > 0 && section[indexPath.row - 1] is BaseInlineRowType && section[indexPath.row - 1]._inlineRow != nil {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard let section = form[sourceIndexPath.section] as? BaseMultivaluedSection else { return sourceIndexPath }
        guard sourceIndexPath.section == proposedDestinationIndexPath.section else { return sourceIndexPath }

        let destRow = form[proposedDestinationIndexPath]
        if destRow is BaseInlineRowType && destRow._inlineRow != nil {
            return IndexPath(row: proposedDestinationIndexPath.row + (sourceIndexPath.row < proposedDestinationIndexPath.row ? 1 : -1), section:sourceIndexPath.section)
        }

        if proposedDestinationIndexPath.row > 0 {
            let previousRow = form[IndexPath(row: proposedDestinationIndexPath.row - 1, section: proposedDestinationIndexPath.section)]
            if previousRow is BaseInlineRowType && previousRow._inlineRow != nil {
                return IndexPath(row: proposedDestinationIndexPath.row + (sourceIndexPath.row < proposedDestinationIndexPath.row ? 1 : -1), section:sourceIndexPath.section)
            }
        }
        if section.multivaluedOptions.contains(.Insert) && proposedDestinationIndexPath.row == section.count - 1 {
            return IndexPath(row: section.count - 2, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

        guard var section = form[sourceIndexPath.section] as? BaseMultivaluedSection else { return }
        if sourceIndexPath.row < section.count && destinationIndexPath.row < section.count && sourceIndexPath.row != destinationIndexPath.row {

            let sourceRow = form[sourceIndexPath]
            animateTableView = false
            section.remove(at: sourceIndexPath.row)
            section.insert(sourceRow, at: destinationIndexPath.row)
            animateTableView = true
            // update the accessory view
            let _ = inputAccessoryView(for: sourceRow)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let section = form[indexPath.section] as? BaseMultivaluedSection else {
            if form[indexPath].trailingSwipe.actions.count > 0 {
                return .delete
            }
            return .none
        }
        if section.multivaluedOptions.contains(.Insert) && indexPath.row == section.count - 1 {
            return section.showInsertIconInAddButton ? .insert : .none
        }
        if section.multivaluedOptions.contains(.Delete) {
            return .delete
        }
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return self.tableView(tableView, editingStyleForRowAt: indexPath) != .none
    }

    @available(iOS 11,*)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !form[indexPath].leadingSwipe.actions.isEmpty else {
            return nil
        }
        return form[indexPath].leadingSwipe.contextualConfiguration
    }

    @available(iOS 11,*)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !form[indexPath].trailingSwipe.actions.isEmpty else {
            return nil
        }
        return form[indexPath].trailingSwipe.contextualConfiguration
    }

    @available(iOS, deprecated: 13, message: "UITableViewRowAction is deprecated, use leading/trailingSwipe actions instead")
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?{
        guard let actions = form[indexPath].trailingSwipe.contextualActions as? [UITableViewRowAction], !actions.isEmpty else {
            return nil
        }
        return actions
    }
}

extension FormViewController : UITableViewDataSource {

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return form.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        form[indexPath].updateCell()
        return form[indexPath].baseCell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return form[section].header?.title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return form[section].footer?.title
    }


    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return 0
    }
}


extension FormViewController : UIScrollViewDelegate {

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let tableView = tableView, scrollView === tableView else { return }
        tableView.endEditing(true)
    }
}

extension FormViewController {

    // MARK: KeyBoard Notifications

    /**
     Called when the keyboard will appear. Adjusts insets of the tableView and scrolls it if necessary.
     */
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let table = tableView, let cell = table.findFirstResponder()?.formCell() else { return }
        let keyBoardInfo = notification.userInfo!
        let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue

        let keyBoardFrame = table.window!.convert(endFrame.cgRectValue, to: table.superview)
        var newBottomInset = table.frame.origin.y + table.frame.size.height - keyBoardFrame.origin.y + rowKeyboardSpacing
        if #available(iOS 11.0, *) {
            newBottomInset = newBottomInset - tableView.safeAreaInsets.bottom
        }
        var tableInsets = table.contentInset
        var scrollIndicatorInsets = table.scrollIndicatorInsets
        oldBottomInset = oldBottomInset ?? tableInsets.bottom
        if newBottomInset > oldBottomInset! {
            tableInsets.bottom = newBottomInset
            scrollIndicatorInsets.bottom = tableInsets.bottom
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
            table.contentInset = tableInsets
            table.scrollIndicatorInsets = scrollIndicatorInsets
            if let selectedRow = table.indexPath(for: cell) {
                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 11 {
                    let rect = table.rectForRow(at: selectedRow)
                    table.scrollRectToVisible(rect, animated: animateScroll)
                } else {
                    table.scrollToRow(at: selectedRow, at: defaultScrollPosition, animated: animateScroll)
                }
            }
            UIView.commitAnimations()
        }
    }

    /**
     Called when the keyboard will disappear. Adjusts insets of the tableView.
     */
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let table = tableView, let oldBottom = oldBottomInset else { return }
        let keyBoardInfo = notification.userInfo!
        var tableInsets = table.contentInset
        var scrollIndicatorInsets = table.scrollIndicatorInsets
        tableInsets.bottom = oldBottom
        scrollIndicatorInsets.bottom = tableInsets.bottom
        oldBottomInset = nil
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        table.contentInset = tableInsets
        table.scrollIndicatorInsets = scrollIndicatorInsets
        UIView.commitAnimations()
    }
}
