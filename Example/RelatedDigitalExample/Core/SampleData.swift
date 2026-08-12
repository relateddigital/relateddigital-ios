//
//  SampleData.swift
//  RelatedDigitalExample
//
//  Randomised e-commerce values used to build realistic analytics payloads.
//

import Foundation

/// One coherent set of product/basket values, regenerated per event so repeated
/// taps produce distinct traffic in the Related Digital panel.
struct SampleBasket {

    let productCode1: String
    let productCode2: String
    let productName1: String
    let productName2: String
    let price1: Double
    let price2: Double
    let quantity1: Int
    let quantity2: Int
    let inventory: Int
    let basketId: Int
    let orderId: Int
    let categoryId: Int
    let searchKeyword: String
    let searchResultCount: Int
    let bannerCode: Int
    let brand: String
    let gender: String

    static func random() -> SampleBasket {
        let brands = ["Acme", "Northwind", "Contoso", "Fabrikam", "Litware"]
        let keywords = ["laptop", "sneakers", "coffee maker", "backpack", "headphones"]
        let code1 = Int.random(in: 1...1000)
        var code2 = Int.random(in: 1...1000)
        while code2 == code1 { code2 = Int.random(in: 1...1000) }

        return SampleBasket(
            productCode1: "PRD-\(code1)",
            productCode2: "PRD-\(code2)",
            productName1: "Product \(code1)",
            productName2: "Product \(code2)",
            price1: Double.random(in: 10...10_000),
            price2: Double.random(in: 10...10_000),
            quantity1: Int.random(in: 1...10),
            quantity2: Int.random(in: 1...10),
            inventory: Int.random(in: 1...100),
            basketId: Int.random(in: 1...10_000),
            orderId: Int.random(in: 1...10_000),
            categoryId: Int.random(in: 1...100),
            searchKeyword: keywords.randomElement()!,
            searchResultCount: Int.random(in: 0...100),
            bannerCode: Int.random(in: 1...100),
            brand: brands.randomElement()!,
            gender: Bool.random() ? "f" : "m"
        )
    }

    var lineTotal1: String { (price1 * Double(quantity1)).priceString }
    var lineTotal2: String { (price2 * Double(quantity2)).priceString }
}

extension Double {

    /// Related Digital expects a dot-separated price with at most two decimals.
    var priceString: String {
        Double.priceFormatter.string(from: NSNumber(value: self)) ?? "1.00"
    }

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.decimalSeparator = "."
        f.groupingSeparator = ""
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
}
