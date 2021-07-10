//
//  CellType.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit

// MARK: Cell Protocols

protocol BaseCellType : AnyObject {

    /// Method that will return the height of the cell
    var height : (() -> CGFloat)? { get }

    /**
     Method called once when creating a cell. Responsible for setting up the cell.
     */
    func setup()

    /**
     Method called each time the cell is updated (e.g. 'cellForRowAtIndexPath' is called). Responsible for updating the cell.
     */
    func update()

    /**
     Method called each time the cell is selected (tapped on by the user).
     */
    func didSelect()

    /**
     Called when cell is about to become first responder
     
     - returns: If the cell should become first responder.
     */
    func cellCanBecomeFirstResponder() -> Bool

    /**
     Method called when the cell becomes first responder
     */
    func cellBecomeFirstResponder(withDirection: Direction) -> Bool

    /**
     Method called when the cell resigns first responder
     */
    func cellResignFirstResponder() -> Bool

}

protocol TypedCellType: BaseCellType {

    associatedtype Value: Equatable

    /// The row associated to this cell.
    var row: RowOf<Value>! { get set }
}

protocol CellType: TypedCellType {}

