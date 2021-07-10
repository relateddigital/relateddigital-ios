//
//  SwipeActions.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

typealias SwipeActionHandler = (SwipeAction, BaseRow, ((Bool) -> Void)?) -> Void

class SwipeAction: ContextualAction {
    let handler: SwipeActionHandler
    let style: Style

    var actionBackgroundColor: UIColor?
    var image: UIImage?
    var title: String?

    @available (*, deprecated, message: "Use actionBackgroundColor instead")
    var backgroundColor: UIColor? {
        get { return actionBackgroundColor }
        set { self.actionBackgroundColor = newValue }
    }

    init(style: Style, title: String?, handler: @escaping SwipeActionHandler){
        self.style = style
        self.title = title
        self.handler = handler
    }

    func contextualAction(forRow: BaseRow) -> ContextualAction {
        var action: ContextualAction
        if #available(iOS 11, *){
            action = UIContextualAction(style: style.contextualStyle as! UIContextualAction.Style, title: title){ [weak self] action, view, completion -> Void in
                guard let strongSelf = self else{ return }
                strongSelf.handler(strongSelf, forRow) { shouldComplete in
                    if #available(iOS 13, *) { // starting in iOS 13, completion handler is not removing the row automatically, so we need to remove it ourselves
                        if shouldComplete && action.style == .destructive {
                            forRow.section?.remove(at: forRow.indexPath!.row)
                        }
                    }
                    completion(shouldComplete)
                }
            }
        } else {
            action = UITableViewRowAction(style: style.contextualStyle as! UITableViewRowAction.Style,title: title){ [weak self] (action, indexPath) -> Void in
                guard let strongSelf = self else{ return }
                strongSelf.handler(strongSelf, forRow) { _ in
                    DispatchQueue.main.async {
                        guard action.style == .destructive else {
                            forRow.baseCell?.formViewController()?.tableView?.setEditing(false, animated: true)
                            return
                        }
                        forRow.section?.remove(at: indexPath.row)
                    }
                }
            }
        }
        if let color = self.actionBackgroundColor {
            action.actionBackgroundColor = color
        }
        if let image = self.image {
            action.image = image
        }
        return action
    }
    
    enum Style {
        case normal
        case destructive
        
        var contextualStyle: ContextualStyle {
            if #available(iOS 11, *){
                switch self{
                case .normal:
                    return UIContextualAction.Style.normal
                case .destructive:
                    return UIContextualAction.Style.destructive
                }
            } else {
                switch self{
                case .normal:
                    return UITableViewRowAction.Style.normal
                case .destructive:
                    return UITableViewRowAction.Style.destructive
                }
            }
        }
    }
}

struct SwipeConfiguration {
    
    unowned var row: BaseRow
    
    init(_ row: BaseRow){
        self.row = row
    }
    
    var performsFirstActionWithFullSwipe = false
    var actions: [SwipeAction] = []
}

extension SwipeConfiguration {
    @available(iOS 11.0, *)
    var contextualConfiguration: UISwipeActionsConfiguration? {
        let contextualConfiguration = UISwipeActionsConfiguration(actions: self.contextualActions as! [UIContextualAction])
        contextualConfiguration.performsFirstActionWithFullSwipe = self.performsFirstActionWithFullSwipe
        return contextualConfiguration
    }

    var contextualActions: [ContextualAction]{
        return self.actions.map { $0.contextualAction(forRow: self.row) }
    }
}

protocol ContextualAction {
    var actionBackgroundColor: UIColor? { get set }
    var image: UIImage? { get set }
    var title: String? { get set }
}

extension UITableViewRowAction: ContextualAction {
    var image: UIImage? {
        get { return nil }
        set { return }
    }

    var actionBackgroundColor: UIColor? {
        get { return backgroundColor }
        set { self.backgroundColor = newValue }
    }
}

@available(iOS 11.0, *)
extension UIContextualAction: ContextualAction {

    var actionBackgroundColor: UIColor? {
        get { return backgroundColor }
        set { self.backgroundColor = newValue }
    }

}

protocol ContextualStyle{}
extension UITableViewRowAction.Style: ContextualStyle {}

@available(iOS 11.0, *)
extension UIContextualAction.Style: ContextualStyle {}
