//
//  AnalyticsViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 13.07.2021.
//

import UIKit
import RelatedDigitalIOS
import CleanyModal
import Eureka
import SplitRow

enum RelatedDigitalEventType: String, CaseIterable {
    case login = "Login"
    case loginWithExtraParameters = "Login with Extra Parameters"
    case signUp  = "Sign Up"
    case pageView = "Page View"
    case productView = "Product View"
    case productAddToCart = "Product Add to Cart"
    case productPurchase = "Product Purchase"
    case productCategoryPageView = "Product Category Page View"
    case inAppSearch = "In App Search"
    case bannerClick = "Banner Click"
    case addToFavorites = "Add to Favorites"
    case removeFromFavorites = "Remove from Favorites"
    case sendingCampaignParameters = "Sending Campaign Parameters"
    case pushMessage = "Push Message"
    case getExVisitorId = "Get exVisitor ID"
    case logout = "Logout"
    case requestIDFA = "Request IDFA"
    case sendLocationPermission = "Send Location Permission"
}

class AnalyticsViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section("Change Page")
        <<< changePage()
        
        form +++ initializeForm()
    }
    
    fileprivate func changePage() -> SplitRow<ButtonRow, ButtonRow> {
        return SplitRow() {
            $0.rowLeftPercentage = 0.5
            
            $0.rowLeft = ButtonRow {
                $0.title = "Push Module"
            }.onCellSelection({ _, _ in
                self.goToPushViewController()
            })
            
            $0.rowRight = ButtonRow {
                $0.title = "Analytics Module"
                $0.disabled = true
            }
        }
    }
    
    private func initializeForm() -> Section {
        
        
        let section = Section("Analytics".uppercased(with: Locale(identifier: "en_US")))
        section.append(TextRow("exVisitorId") {
            $0.title = "exVisitorId"
            $0.value = relatedDigitalProfile.userKey
            $0.cell.textField.autocapitalizationType = .none
        })
        section.append(TextRow("email") {
            $0.title = "email"
            $0.value = relatedDigitalProfile.userEmail
            $0.cell.textField.autocapitalizationType = .none
        })
        
        for eventType in RelatedDigitalEventType.allCases {
            section.append(ButtonRow {
                $0.title = eventType.rawValue
            }
                            .onCellSelection { _, row in
                if row.title == RelatedDigitalEventType.logout.rawValue {
                    RelatedDigital.logout()
                    print("log out!!")
                } else if row.title == RelatedDigitalEventType.getExVisitorId.rawValue {
                    print(RelatedDigital.exVisitorId ?? "")
                } else if row.title == RelatedDigitalEventType.requestIDFA.rawValue {
                    RelatedDigital.requestIDFA()
                } else if row.title == RelatedDigitalEventType.sendLocationPermission.rawValue {
                    RelatedDigital.sendLocationPermission()
                } else {
                    self.customEvent(eventType)
                }
            })
        }
        return section
    }
    
    private func customEvent(_ eventType: RelatedDigitalEventType) {
        let exVisitorId: String = ((self.form.rowBy(tag: "exVisitorId") as TextRow?)!.value
                                   ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email: String = ((self.form.rowBy(tag: "email") as TextRow?)!.value
                             ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var properties = [String: String]()
        let randomValues = getRandomProductValues()
        
        switch eventType {
        case .login, .signUp, .loginWithExtraParameters:
            properties["OM.sys.TokenID"] = relatedDigitalProfile.appToken //"Token ID to use for push messages"
            properties["OM.sys.AppID"] = relatedDigitalProfile.appAlias // "App ID to use for push messages"
            if exVisitorId.isEmpty {
                self.showModal(title: "Warning", message: "exVisitorId can not be empty")
                return
            } else {
                relatedDigitalProfile.userKey = exVisitorId
                relatedDigitalProfile.userEmail = email
                DataManager.saveRelatedDigitalProfile(relatedDigitalProfile)
                if eventType == .login {
                    RelatedDigital.login(exVisitorId: relatedDigitalProfile.userKey, properties: properties)
                } else if eventType == .signUp {
                    RelatedDigital.signUp(exVisitorId: relatedDigitalProfile.userKey, properties: properties)
                } else {
                    properties["OM.vseg1"] = "seg1val" // Visitor Segment 1
                    properties["OM.vseg2"] = "seg2val" // Visitor Segment 2
                    properties["OM.vseg3"] = "seg3val" // Visitor Segment 3
                    properties["OM.vseg4"] = "seg4val" // Visitor Segment 4
                    properties["OM.vseg5"] = "seg5val" // Visitor Segment 5
                    properties["OM.bd"] = "1977-03-15" // Birthday
                    properties["OM.gn"] = randomValues.randomGender // Gender
                    properties["OM.loc"] = "Bursa" // Location
                    RelatedDigital.login(exVisitorId: relatedDigitalProfile.userKey, properties: properties)
                }
//                Euromsg.setEuroUserId(userKey: relatedDigitalProfile.userKey)
//                Euromsg.setEmail(email: relatedDigitalProfile.userEmail, permission: true)
                return
            }
        case .pageView:
            RelatedDigital.customEvent("Page Name", properties: [String: String]())
            return
        case .productView:
            properties["OM.pv"] = "\(randomValues.randomProductCode1)" // Product Code
            properties["OM.pn"] = "Name-\(randomValues.randomProductCode1)" //Product Name
            properties["OM.ppr"] = randomValues.randomProductPrice1.formatPrice() // Product Price
            properties["OM.pv.1"] = "Brand" //Product Brand
            properties["OM.inv"] = "\(randomValues.randomInventory)" //Number of items in stock
            RelatedDigital.customEvent("Product View", properties: properties)
            return
        case .productAddToCart:
            properties["OM.pbid"] = "\(randomValues.randomBasketID)" // Basket ID
            properties["OM.pb"] = "\(randomValues.randomProductCode1);\(randomValues.randomProductCode2)"
            //Product1 Code;Product2 Code
            properties["OM.pu"] = "\(randomValues.randomProductQuantity1);\(randomValues.randomProductQuantity2)"
            // Product1 Quantity;Product2 Quantity
            let price1 = (randomValues.randomProductPrice1 * Double(randomValues.randomProductQuantity1)).formatPrice()
            let price2 = (randomValues.randomProductPrice2 * Double(randomValues.randomProductQuantity2)).formatPrice()
            properties["OM.ppr"] = "\(price1);\(price2)"
            RelatedDigital.customEvent("Cart", properties: properties)
            return
        case .productPurchase:
            properties["OM.tid"] = "\(randomValues.randomOrderID)" // Order ID
            properties["OM.pp"] = "\(randomValues.randomProductCode1);\(randomValues.randomProductCode2)"
            //Product1 Code;Product2 Code
            properties["OM.pu"] = "\(randomValues.randomProductQuantity1);\(randomValues.randomProductQuantity2)"
            // Product1 Quantity;Product2 Quantity
            let price1 = (randomValues.randomProductPrice1 * Double(randomValues.randomProductQuantity1)).formatPrice()
            let price2 = (randomValues.randomProductPrice2 * Double(randomValues.randomProductQuantity2)).formatPrice()
            properties["OM.ppr"] = "\(price1);\(price2)"
            RelatedDigital.customEvent("Purchase", properties: properties)
            return
        case .productCategoryPageView:
            properties["OM.clist"] = "\(randomValues.randomCategoryID)" // Category Code/Category ID
            RelatedDigital.customEvent("Category View", properties: properties)
            return
        case .inAppSearch:
            properties["OM.OSS"] = "laptop" // Search Keyword
            properties["OM.OSSR"] = "\(randomValues.randomNumberOfSearchResults)" // Number of Search Results
            RelatedDigital.customEvent("In App Search", properties: properties)
            return
        case .bannerClick:
            properties["OM.OSB"] = "\(randomValues.randomBannerCode)" // Banner Name/Banner Code
            RelatedDigital.customEvent("Banner Click", properties: properties)
            return
        case .addToFavorites:
            properties["OM.pf"] = "\(randomValues.randomProductCode1)" // Product Code
            properties["OM.pfu"] = "1"
            properties["OM.ppr"] = randomValues.randomProductPrice1.formatPrice() // Product Price
            RelatedDigital.customEvent("Add To Favorites", properties: properties)
            return
        case .removeFromFavorites:
            properties["OM.pf"] = "\(randomValues.randomProductCode1)" // Product Code
            properties["OM.pfu"] = "-1"
            properties["OM.ppr"] = randomValues.randomProductPrice1.formatPrice() // Product Price
            RelatedDigital.customEvent("Add To Favorites", properties: properties)
            return
        case .sendingCampaignParameters:
            properties["utm_source"] = "euromsg"
            properties["utm_medium"] = "push"
            properties["utm_campaign"] = "euromsg campaign"
            properties["OM.csource"] = "euromsg"
            properties["OM.cmedium"] = "push"
            properties["OM.cname"] = "euromsg campaign"
            RelatedDigital.customEvent("Login Page", properties: properties)
            return
        case .pushMessage:
            properties["OM.sys.TokenID"] = relatedDigitalProfile.appToken //"Token ID to use for push messages"
            properties["OM.sys.AppID"] = relatedDigitalProfile.appAlias // "App ID to use for push messages"
            RelatedDigital.customEvent("RegisterToken", properties: properties)
            return
        default:
            return
        }
    }
    
    private func showModal(title: String, message: String) {
        let styleSettings = CleanyAlertConfig.getDefaultStyleSettings()
        styleSettings[.cornerRadius] = 18
        let alertViewController = CleanyAlertViewController(title: title,
                                                            message: message,
                                                            preferredStyle: .alert,
                                                            styleSettings: styleSettings)
        alertViewController.addAction(title: "Dismiss", style: .default)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    private func getRandomProductValues() -> RandomProduct {
        let randomProductCode1 = Int.random(min: 1, max: 1000)
        let randomProductCode2 = Int.random(min: 1, max: 1000, except: [randomProductCode1])
        let randomProductPrice1 = Double.random(in: 10..<10000)
        let randomProductPrice2 = Double.random(in: 10..<10000)
        let randomProductQuantity1 = Int.random(min: 1, max: 10)
        let randomProductQuantity2 = Int.random(min: 1, max: 10)
        let randomInventory = Int.random(min: 1, max: 100)
        let randomBasketID = Int.random(min: 1, max: 10000)
        let randomOrderID = Int.random(min: 1, max: 10000)
        let randomCategoryID = Int.random(min: 1, max: 100)
        let randomNumberOfSearchResults = Int.random(min: 1, max: 100)
        let randomBannerCode = Int.random(min: 1, max: 100)
        let genders: [String] = ["f", "m"]
        let randomGender = genders[Int.random(min: 0, max: 1)]
        
        return RandomProduct(randomProductCode1: randomProductCode1,
                             randomProductCode2: randomProductCode2,
                             randomProductPrice1: randomProductPrice1,
                             randomProductPrice2: randomProductPrice2,
                             randomProductQuantity1: randomProductQuantity1,
                             randomProductQuantity2: randomProductQuantity2,
                             randomInventory: randomInventory,
                             randomBasketID: randomBasketID,
                             randomOrderID: randomOrderID,
                             randomCategoryID: randomCategoryID,
                             randomNumberOfSearchResults: randomNumberOfSearchResults,
                             randomBannerCode: randomBannerCode,
                             genders: genders,
                             randomGender: randomGender)
    }
    
    func goToPushViewController() {
        let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
        self.view.window?.rootViewController = appDelegate?.getPushViewController()
    }
    
}

struct RandomProduct {
    let randomProductCode1: Int
    let randomProductCode2: Int
    let randomProductPrice1: Double
    let randomProductPrice2: Double
    let randomProductQuantity1: Int
    let randomProductQuantity2: Int
    let randomInventory: Int
    let randomBasketID: Int
    let randomOrderID: Int
    let randomCategoryID: Int
    let randomNumberOfSearchResults: Int
    let randomBannerCode: Int
    let genders: [String]
    let randomGender: String
}
