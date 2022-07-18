//
//  downhsViewControllerModel.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 13.04.2022.
//

import Foundation
import UIKit


class downHsViewControllerModel {
    
    func mapServiceModelToNeededModel(serviceModel: downHsViewServiceModel) -> downHsModel {
        var model = downHsModel()
        model.serviceModel = serviceModel
        model.image = UIImage(data: getDataOfImage(urlString: model.serviceModel?.img ?? ""))
        if model.serviceModel?.imagePosition == "left" {
            model.imagePos = .left
        }
        if model.serviceModel?.textPosition == "bottom" {
            model.textPos = .bottom
        }
        if model.serviceModel?.emailPermitText?.count ?? 0 == 0 {
            model.lastTextHidden = true
        }
        
        return model
    }
    
    private func getDataOfImage(urlString : String) -> Data {
        
        let image: Data? = {
            var data: Data?
            if let iUrl = URL(string: urlString)  {
                do {
                    data = try Data(contentsOf: iUrl, options: [.mappedIfSafe])
                } catch {
                    RDLogger.error("image failed to load from url \(iUrl)")
                }
            }
            return data
        }()
        
        return image ?? Data()
    }
}

struct downHsModel {
    var image : UIImage?
    var imagePos : imagePosition? = .right
    var textPos : subTitlePosition? = .top
    var lastTextHidden : Bool = false
    var serviceModel:downHsViewServiceModel?
}

enum imagePosition {
    case right
    case left
}

enum subTitlePosition {
    case top
    case bottom
}

struct downHsViewServiceModel : TargetingActionViewModel {
    
    var targetingActionType: TargetingActionType
    var actId:Int?
    
    
    //actionData
    var title:String?
    var message:String?
    var placeholder:String?
    var buttonLabel:String?
    var emailPermitText:String?
    var consentText:String?
    var checkConsentMessage:String?
    var invalidEmailMessage:String?
    var successMessage:String?
    var taTemplate:String = "taTemplate"
    var img:String?
    
    //extended props
    var imagePosition:String?
    var titleTextColor:String?
    var titleFontFamily:String?
    var titleCustomFontFamilyIos:String?
    var titleTextSize:String?
    var textPosition:String?
    var textColor:String?
    var textFontFamily:String?
    var textCustomFontFamilyIos:String?
    var textSize:String?
    var buttonColor:String?
    var buttonTextColor:String?
    var buttonFontFamily:String?
    var buttonCustomFontFamilyIos:String?
    var buttonTextSize:String?
    var emailPermitTextSize:String?
    var emailPermitTextUrl:String?
    var consentTextSize:String?
    var consentTextUrl:String?
    var closeButtonColor:String?
    var backgroundColor:String?
}
