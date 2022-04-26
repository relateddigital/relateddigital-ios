//
//  downhsViewControllerModel.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 13.04.2022.
//

import Foundation
import UIKit


class downhsViewControllerModel {
    
}

struct downhsModel {
    var imagePos : imagePosition? = .right
    var textPos : subTitlePosition? = .down
    var lastTextHidden : Bool = false
}

enum imagePosition {
    case right
    case left
}

enum subTitlePosition {
    case up
    case down
}

