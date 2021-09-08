//
//  Core.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import Foundation
import UIKit

// MARK: Row

class RowDefaults {
    static var cellUpdate = [String: (BaseCell, BaseRow) -> Void]()
    static var cellSetup = [String: (BaseCell, BaseRow) -> Void]()
    static var onCellHighlightChanged = [String: (BaseCell, BaseRow) -> Void]()
    static var rowInitialization = [String: (BaseRow) -> Void]()
    static var onRowValidationChanged = [String: (BaseCell, BaseRow) -> Void]()
    static var rawCellUpdate = [String: Any]()
    static var rawCellSetup = [String: Any]()
    static var rawOnCellHighlightChanged = [String: Any]()
    static var rawRowInitialization = [String: Any]()
    static var rawOnRowValidationChanged = [String: Any]()
}

// MARK: FormCells

struct CellProvider<Cell: BaseCell> where Cell: CellType {

    init() {}
    
    /**
     Creates the cell with the specified style.

     - parameter cellStyle: The style with which the cell will be created.

     - returns: the cell
     */
    func makeCell(style: UITableViewCell.CellStyle) -> Cell {
        return Cell.init(style: style, reuseIdentifier: nil)
    }
}

/**
 Enumeration that defines how a controller should be created.

 - Callback->VCType: Creates the controller inside the specified block
 - StoryBoard:       Loads the controller from a Storyboard by its storyboard id
 */
enum ControllerProvider<VCType: UIViewController> {

    /**
     *  Creates the controller inside the specified block
     */
    case callback(builder: (() -> VCType))

    /**
     *  Loads the controller from a Storyboard by its storyboard id
     */
    case storyBoard(storyboardId: String, storyboardName: String, bundle: Bundle?)

    func makeController() -> VCType {
        switch self {
            case .callback(let builder):
                return builder()
            case .storyBoard(let storyboardId, let storyboardName, let bundle):
                let sb = UIStoryboard(name: storyboardName, bundle: bundle ?? Bundle(for: VCType.self))
                return sb.instantiateViewController(withIdentifier: storyboardId) as! VCType
        }
    }
}

/**
 Defines how a controller should be presented.

 - Show?:           Shows the controller with `showViewController(...)`.
 - PresentModally?: Presents the controller modally.
 - SegueName?:      Performs the segue with the specified identifier (name).
 - SegueClass?:     Performs a segue from a segue class.
 */
enum PresentationMode<VCType: UIViewController> {

    /**
     *  Shows the controller, created by the specified provider, with `showViewController(...)`.
     */
    case show(controllerProvider: ControllerProvider<VCType>, onDismiss: ((UIViewController) -> Void)?)

    /**
     *  Presents the controller, created by the specified provider, modally.
     */
    case presentModally(controllerProvider: ControllerProvider<VCType>, onDismiss: ((UIViewController) -> Void)?)

    /**
     *  Performs the segue with the specified identifier (name).
     */
    case segueName(segueName: String, onDismiss: ((UIViewController) -> Void)?)

    /**
     *  Performs a segue from a segue class.
     */
    case segueClass(segueClass: UIStoryboardSegue.Type, onDismiss: ((UIViewController) -> Void)?)

    case popover(controllerProvider: ControllerProvider<VCType>, onDismiss: ((UIViewController) -> Void)?)

    var onDismissCallback: ((UIViewController) -> Void)? {
        switch self {
            case .show(_, let completion):
                return completion
            case .presentModally(_, let completion):
                return completion
            case .segueName(_, let completion):
                return completion
            case .segueClass(_, let completion):
                return completion
            case .popover(_, let completion):
                return completion
        }
    }

    /**
     Present the view controller provided by PresentationMode. Should only be used from custom row implementation.

     - parameter viewController:           viewController to present if it makes sense (normally provided by makeController method)
     - parameter row:                      associated row
     - parameter presentingViewController: form view controller
     */
    func present(_ viewController: VCType!, row: BaseRow, presentingController: FormViewController) {
        switch self {
            case .show(_, _):
                presentingController.show(viewController, sender: row)
            case .presentModally(_, _):
                presentingController.present(viewController, animated: true)
            case .segueName(let segueName, _):
                presentingController.performSegue(withIdentifier: segueName, sender: row)
            case .segueClass(let segueClass, _):
                let segue = segueClass.init(identifier: row.tag, source: presentingController, destination: viewController)
                presentingController.prepare(for: segue, sender: row)
                segue.perform()
            case .popover(_, _):
                guard let porpoverController = viewController.popoverPresentationController else {
                    fatalError()
                }
                porpoverController.sourceView = porpoverController.sourceView ?? presentingController.tableView
                presentingController.present(viewController, animated: true)
            }

    }

    /**
     Creates the view controller specified by presentation mode. Should only be used from custom row implementation.

     - returns: the created view controller or nil depending on the PresentationMode type.
     */
    func makeController() -> VCType? {
        switch self {
            case .show(let controllerProvider, let completionCallback):
                let controller = controllerProvider.makeController()
                let completionController = controller as? RowControllerType
                if let callback = completionCallback {
                    completionController?.onDismissCallback = callback
                }
                return controller
            case .presentModally(let controllerProvider, let completionCallback):
                let controller = controllerProvider.makeController()
                let completionController = controller as? RowControllerType
                if let callback = completionCallback {
                    completionController?.onDismissCallback = callback
                }
                return controller
            case .popover(let controllerProvider, let completionCallback):
                let controller = controllerProvider.makeController()
                controller.modalPresentationStyle = .popover
                let completionController = controller as? RowControllerType
                if let callback = completionCallback {
                    completionController?.onDismissCallback = callback
                }
                return controller
            default:
                return nil
        }
    }
}

/**
 *  Protocol to be implemented by custom formatters.
 */
protocol FormatterProtocol {
    func getNewPosition(forPosition: UITextPosition, inTextInput textInput: UITextInput, oldValue: String?, newValue: String?) -> UITextPosition
}

// MARK: Predicate Machine

enum ConditionType {
    case hidden, disabled
}

/**
 Enumeration that are used to specify the disbaled and hidden conditions of rows

 - Function:  A function that calculates the result
 - Predicate: A predicate that returns the result
 */
enum Condition {
    /**
     *  Calculate the condition inside a block
     *
     *  @param            Array of tags of the rows this function depends on
     *  @param Form->Bool The block that calculates the result
     *
     *  @return If the condition is true or false
     */
    case function([String], (Form)->Bool)

    /**
     *  Calculate the condition using a NSPredicate
     *
     *  @param NSPredicate The predicate that will be evaluated
     *
     *  @return If the condition is true or false
     */
    case predicate(NSPredicate)
}

extension Condition : ExpressibleByBooleanLiteral {

    /**
     Initialize a condition to return afixed boolean value always
     */
    init(booleanLiteral value: Bool) {
        self = Condition.function([]) { _ in return value }
    }
}

extension Condition : ExpressibleByStringLiteral {

    /**
     Initialize a Condition with a string that will be converted to a NSPredicate
     */
    init(stringLiteral value: String) {
        self = .predicate(NSPredicate(format: value))
    }

    /**
     Initialize a Condition with a string that will be converted to a NSPredicate
     */
    init(unicodeScalarLiteral value: String) {
        self = .predicate(NSPredicate(format: value))
    }

    /**
     Initialize a Condition with a string that will be converted to a NSPredicate
     */
    init(extendedGraphemeClusterLiteral value: String) {
        self = .predicate(NSPredicate(format: value))
    }
}

// MARK: Errors

/**
Errors thrown by Eureka

 - duplicatedTag: When a section or row is inserted whose tag dows already exist
 - rowNotInSection: When a row was expected to be in a Section, but is not.
*/
enum EurekaError: Error {
    case duplicatedTag(tag: String)
    case rowNotInSection(row: BaseRow)
}

//Mark: FormViewController

/**
*  A protocol implemented by FormViewController
*/
protocol FormViewControllerProtocol {
    var tableView: UITableView! { get }

    func beginEditing<T>(of: Cell<T>)
    func endEditing<T>(of: Cell<T>)

    func insertAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation
    func deleteAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation
    func reloadAnimation(oldRows: [BaseRow], newRows: [BaseRow]) -> UITableView.RowAnimation
    func insertAnimation(forSections sections: [Section]) -> UITableView.RowAnimation
    func deleteAnimation(forSections sections: [Section]) -> UITableView.RowAnimation
    func reloadAnimation(oldSections: [Section], newSections: [Section]) -> UITableView.RowAnimation
}

/**
 *  Navigation options for a form view controller.
 */
struct RowNavigationOptions: OptionSet {

    private enum NavigationOptions: Int {
        case disabled = 0, enabled = 1, stopDisabledRow = 2, skipCanNotBecomeFirstResponderRow = 4
    }
    let rawValue: Int
     init(rawValue: Int) { self.rawValue = rawValue}
    private init(_ options: NavigationOptions ) { self.rawValue = options.rawValue }

    /// No navigation.
    static let Disabled = RowNavigationOptions(.disabled)

    /// Full navigation.
    static let Enabled = RowNavigationOptions(.enabled)

    /// Break navigation when next row is disabled.
    static let StopDisabledRow = RowNavigationOptions(.stopDisabledRow)

    /// Break navigation when next row cannot become first responder.
    static let SkipCanNotBecomeFirstResponderRow = RowNavigationOptions(.skipCanNotBecomeFirstResponderRow)
}

/**
 *  Defines the configuration for the keyboardType of FieldRows.
 */
struct KeyboardReturnTypeConfiguration {
    /// Used when the next row is available.
    var nextKeyboardType = UIReturnKeyType.next

    /// Used if next row is not available.
    var defaultKeyboardType = UIReturnKeyType.default

    init() {}

    init(nextKeyboardType: UIReturnKeyType, defaultKeyboardType: UIReturnKeyType) {
        self.nextKeyboardType = nextKeyboardType
        self.defaultKeyboardType = defaultKeyboardType
    }
}

/**
 *  Options that define when an inline row should collapse.
 */
struct InlineRowHideOptions: OptionSet {

    private enum _InlineRowHideOptions: Int {
        case never = 0, anotherInlineRowIsShown = 1, firstResponderChanges = 2
    }
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue}
    private init(_ options: _InlineRowHideOptions ) { self.rawValue = options.rawValue }

    /// Never collapse automatically. Only when user taps inline row.
    static let Never = InlineRowHideOptions(.never)

    /// Collapse qhen another inline row expands. Just one inline row will be expanded at a time.
    static let AnotherInlineRowIsShown = InlineRowHideOptions(.anotherInlineRowIsShown)

    /// Collapse when first responder changes.
    static let FirstResponderChanges = InlineRowHideOptions(.firstResponderChanges)
}



enum Direction { case up, down }

extension FormViewController {

    // MARK: Navigation Methods

    @objc func navigationDone() {
        tableView?.endEditing(true)
    }

    @objc func navigationPrevious() {
        navigateTo(direction: .up)
    }

    @objc func navigationNext() {
        navigateTo(direction: .down)
    }

    func navigateTo(direction: Direction) {
        guard let currentCell = tableView?.findFirstResponder()?.formCell() else { return }
        guard let currentIndexPath = tableView?.indexPath(for: currentCell) else { return }
        guard let nextRow = nextRow(for: form[currentIndexPath], withDirection: direction) else { return }
        if nextRow.baseCell.cellCanBecomeFirstResponder() {
            tableView?.scrollToRow(at: nextRow.indexPath!, at: .none, animated: animateScroll)
            nextRow.baseCell.cellBecomeFirstResponder(withDirection: direction)
        }
    }

    func nextRow(for currentRow: BaseRow, withDirection direction: Direction) -> BaseRow? {

        let options = navigationOptions ?? Form.defaultNavigationOptions
        guard options.contains(.Enabled) else { return nil }
        guard let next = direction == .down ? form.nextRow(for: currentRow) : form.previousRow(for: currentRow) else { return nil }
        if next.isDisabled && options.contains(.StopDisabledRow) {
            return nil
        }
        if !next.baseCell.cellCanBecomeFirstResponder() && !next.isDisabled && !options.contains(.SkipCanNotBecomeFirstResponderRow) {
            return nil
        }
        if !next.isDisabled && next.baseCell.cellCanBecomeFirstResponder() {
            return next
        }
        return nextRow(for: next, withDirection:direction)
    }
}

extension FormViewControllerProtocol {

    // MARK: Helpers

    func makeRowVisible(_ row: BaseRow, destinationScrollPosition: UITableView.ScrollPosition? = .bottom) {
    guard let destinationScrollPosition = destinationScrollPosition else { return }
        guard let cell = row.baseCell, let indexPath = row.indexPath, let tableView = tableView else { return }
        if cell.window == nil || (tableView.contentOffset.y + tableView.frame.size.height <= cell.frame.origin.y + cell.frame.size.height) {
            tableView.scrollToRow(at: indexPath, at: destinationScrollPosition, animated: true)
        }
    }
}

