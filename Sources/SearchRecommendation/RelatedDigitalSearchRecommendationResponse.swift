import Foundation

// MARK: - BrandContainer
public struct BrandContainer: Codable {
    public let title: String
    public let isActive: Bool
    public let popularBrands: [PopularBrand]
    public let report: Report

    public enum CodingKeys: String, CodingKey {
        case title = "Title"
        case isActive = "IsActive"
        case popularBrands = "PopularBrands"
        case report
    }
    
    init?(responseDict: [String: Any]) {
        guard
            let title = responseDict[RDConstants.Title] as? String,
            let isActive = responseDict[RDConstants.IsActive] as? Bool,
            let popularBrandsDict = responseDict[RDConstants.PopularBrands] as? [[String: Any]],
            let reportDict = responseDict[RDConstants.Report] as? [String: String],
            let report = Report(responseDict: reportDict)
        else {
            return nil
        }

        let popularBrands = popularBrandsDict.compactMap { PopularBrand(responseDict: $0) }

        self.title = title
        self.isActive = isActive
        self.popularBrands = popularBrands
        self.report = report
    }
}

// MARK: - PopularBrand
public struct PopularBrand: Codable {
    public let name: String
    public let url: String?

    init(responseDict: [String: Any]) {
        self.name = responseDict[RDConstants.Name] as? String ?? ""
        self.url = responseDict[RDConstants.Url] as? String
    }
}

// MARK: - Report
public struct Report: Codable {
    public let impression, click: String

    enum CodingKeys: String, CodingKey {
        case impression = "impression"
        case click = "click"
    }
    
    init?(responseDict: [String: String]) {
        guard
            let impression = responseDict[RDConstants.Impression],
            let click = responseDict[RDConstants.Click]
        else {
            return nil
        }

        self.impression = impression
        self.click = click
    }
}

// MARK: - CategoryContainer
public struct CategoryContainer: Codable {
    public let title: String
    public let isActive: Bool
    public let popularCategories: [PopularCategory]
    public let report: Report

    public enum CodingKeys: String, CodingKey {
        case title = "Title"
        case isActive = "IsActive"
        case popularCategories = "PopularCategories"
        case report
    }
    
    init?(responseDict: [String: Any]) {
        guard
            let title = responseDict[RDConstants.Title] as? String,
            let isActive = responseDict[RDConstants.IsActive] as? Bool,
            let popularCategoriesDict = responseDict[RDConstants.PopularCategories] as? [[String: Any]],
            let reportDict = responseDict[RDConstants.Report] as? [String: String],
            let report = Report(responseDict: reportDict)
        else {
            return nil
        }
        
        let popularCategories = popularCategoriesDict.compactMap { PopularCategory(responseDict: $0) }

        self.title = title
        self.isActive = isActive
        self.popularCategories = popularCategories
        self.report = report
    }
}

// MARK: - PopularCategory
public struct PopularCategory: Codable {
    public let name: String
    public let products: [Product]
    
    init?(responseDict: [String: Any]) {
        guard
            let name = responseDict[RDConstants.Name] as? String,
            let productsDict = responseDict[RDConstants.Products] as? [[String: Any]]
        else {
            return nil
        }
        
        let products = productsDict.compactMap { Product(responseDict: $0) }

        self.name = name
        self.products = products
    }

}

// MARK: - Product
public struct Product: Codable {
    public let name, url, imageUrl, brandName: String
    public let price, discountPrice: Double
    public let code, currency, discountCurrency: String
    
    init?(responseDict: [String: Any]) {
        guard
            let name = responseDict[RDConstants.Name] as? String,
            let url = responseDict[RDConstants.Url] as? String,
            let imageUrl = responseDict[RDConstants.ImageUrl] as? String,
            let brandName = responseDict[RDConstants.BrandName] as? String,
            let price = responseDict[RDConstants.Price] as? Double,
            let discountPrice = responseDict[RDConstants.DiscountPrice] as? Double,
            let code = responseDict[RDConstants.Code] as? String,
            let currency = responseDict[RDConstants.Currency] as? String,
            let discountCurrency = responseDict[RDConstants.DiscountCurrency] as? String
        else {
            return nil
        }

        self.name = name
        self.url = url
        self.imageUrl = imageUrl
        self.brandName = brandName
        self.price = price
        self.discountPrice = discountPrice
        self.code = code
        self.currency = currency
        self.discountCurrency = discountCurrency
    }
}

// MARK: - ProductAreaContainer
public struct ProductAreaContainer: Codable {
    public let title, preTitle: String
    public let changeTitle: Bool
    public let products: [Product]
    public let searchResultMessage: String
    public let report: Report
    
    init?(responseDict: [String: Any]) {
        guard
            let title = responseDict[RDConstants.Title] as? String,
            let preTitle = responseDict[RDConstants.PreTitle] as? String,
            let changeTitle = responseDict[RDConstants.ChangeTitle] as? Bool,
            let productsDict = responseDict[RDConstants.Products] as? [[String: Any]],
            let searchResultMessage = responseDict[RDConstants.SearchResultMessage] as? String,
            let reportDict = responseDict[RDConstants.Report] as? [String: String],
            let report = Report(responseDict: reportDict)
        else {
            return nil
        }
        
        let products = productsDict.compactMap({ Product(responseDict: $0) })
        
        self.title = title
        self.preTitle = preTitle
        self.changeTitle = changeTitle
        self.products = products
        self.searchResultMessage = searchResultMessage
        self.report = report
    }
}

// MARK: - SearchContainer
public struct SearchContainer: Codable {
    public let title: String
    public let isActive: Bool
    public let searchUrlPrefix: String
    public let popularSearches: [PopularSearch]
    public let report: Report

    public enum CodingKeys: String, CodingKey {
        case title = "Title"
        case isActive = "IsActive"
        case searchUrlPrefix = "SearchUrlPrefix"
        case popularSearches = "PopularSearches"
        case report
    }

    init?(responseDict: [String: Any]) {
        guard
            let title = responseDict[RDConstants.Title] as? String,
            let isActive = responseDict[RDConstants.IsActive] as? Bool,
            let searchUrlPrefix = responseDict[RDConstants.SearchUrlPrefix] as? String,
            let popularSearchesDict = responseDict[RDConstants.PopularSearches] as? [[String: Any]],
            let reportDict = responseDict[RDConstants.Report] as? [String: String],
            let report = Report(responseDict: reportDict)
        else {
            return nil
        }

        let popularSearches = popularSearchesDict.compactMap({ PopularSearch(responseDict: $0) })

        self.title = title
        self.isActive = isActive
        self.searchUrlPrefix = searchUrlPrefix
        self.popularSearches = popularSearches
        self.report = report
    }
}

// MARK: - PopularSearch
public struct PopularSearch: Codable {
    public let name: String
    public let url: String?

    init?(responseDict: [String: Any]) {
        guard
            let name = responseDict[RDConstants.Name] as? String,
            let url = responseDict[RDConstants.Url] as? String?
        else {
            return nil
        }

        self.name = name
        self.url = url
    }
}

// MARK: - SearchStyle
public struct SearchStyle: Codable {
    public let fontFamily, textColor, themeColor, titleColor: String
    public let hoverColor, hoverTextColor: String
    public let columnCount, rowCount: Int
    public let querySelectorCss, titleBorderRadius, backgroundColor: String

    init?(responseDict: [String: Any]) {
        guard
            let fontFamily = responseDict[RDConstants.FontFamily] as? String,
            let textColor = responseDict[RDConstants.TextColor] as? String,
            let themeColor = responseDict[RDConstants.ThemeColor] as? String,
            let titleColor = responseDict[RDConstants.TitleColor] as? String,
            let hoverColor = responseDict[RDConstants.HoverColor] as? String,
            let hoverTextColor = responseDict[RDConstants.HoverTextColor] as? String,
            let columnCount = responseDict[RDConstants.ColumnCount] as? Int,
            let rowCount = responseDict[RDConstants.RowCount] as? Int,
            let querySelectorCss = responseDict[RDConstants.QuerySelectorCss] as? String,
            let titleBorderRadius = responseDict[RDConstants.TitleBorderRadius] as? String,
            let backgroundColor = responseDict[RDConstants.BackgroundColor] as? String
        else {
            return nil
        }

        self.fontFamily = fontFamily
        self.textColor = textColor
        self.themeColor = themeColor
        self.titleColor = titleColor
        self.hoverColor = hoverColor
        self.hoverTextColor = hoverTextColor
        self.columnCount = columnCount
        self.rowCount = rowCount
        self.querySelectorCss = querySelectorCss
        self.titleBorderRadius = titleBorderRadius
        self.backgroundColor = backgroundColor
    }
}

// MARK: - SearchTemplate
public struct SearchTemplate: Codable {
    public let mainLayout, popularSearches, popularCategories, popularBrands: String
    public let popularProducts, searchItemLayout, listItemLayout: String

    init?(responseDict: [String: Any]) {
        guard
            let mainLayout = responseDict[RDConstants.MainLayout] as? String,
            let popularSearches = responseDict[RDConstants.PopularSearches] as? String,
            let popularCategories = responseDict[RDConstants.PopularCategories] as? String,
            let popularBrands = responseDict[RDConstants.PopularBrands] as? String,
            let popularProducts = responseDict[RDConstants.PopularProducts] as? String,
            let searchItemLayout = responseDict[RDConstants.SearchItemLayout] as? String,
            let listItemLayout = responseDict[RDConstants.ListItemLayout] as? String
        else {
            return nil
        }

        self.mainLayout = mainLayout
        self.popularSearches = popularSearches
        self.popularCategories = popularCategories
        self.popularBrands = popularBrands
        self.popularProducts = popularProducts
        self.searchItemLayout = searchItemLayout
        self.listItemLayout = listItemLayout
    }
}

public struct RelatedDigitalSearchRecommendationResponse: Codable {
    public let queryselector: String?
    public let customCss: String?
    public let customJs: String?
    public let hideSearchIfEmpty: Bool?
    public let productAreaContainer: ProductAreaContainer?
    public let categoryContainer: CategoryContainer?
    public let brandContainer: BrandContainer?
    public let searchContainer: SearchContainer?
    public let searchStyle: SearchStyle?
    public let searchTemplate: SearchTemplate?

    init(responseDict: [String: Any]) {
        self.queryselector = responseDict[RDConstants.Queryselector] as? String
        self.customCss = responseDict[RDConstants.CustomCss] as? String
        self.customJs = responseDict[RDConstants.CustomJs] as? String
        self.hideSearchIfEmpty = responseDict[RDConstants.HideSearchIfEmpty] as? Bool

        self.productAreaContainer = ProductAreaContainer(responseDict: responseDict[RDConstants.ProductAreaContainer] as? [String: Any] ?? [:])
        self.categoryContainer = CategoryContainer(responseDict: responseDict[RDConstants.CategoryContainer] as? [String: Any] ?? [:])
        self.brandContainer = BrandContainer(responseDict: responseDict[RDConstants.BrandContainer] as? [String: Any] ?? [:])
        self.searchContainer = SearchContainer(responseDict: responseDict[RDConstants.SearchContainer] as? [String: Any] ?? [:])
        self.searchStyle = SearchStyle(responseDict: responseDict[RDConstants.SearchStyle] as? [String: Any] ?? [:])
        self.searchTemplate = SearchTemplate(responseDict: responseDict[RDConstants.SearchTemplate] as? [String: Any] ?? [:])
    }
}
