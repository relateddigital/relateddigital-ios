//
//  RelatedDigitalExampleTests.swift
//  RelatedDigitalExampleTests
//
//  Covers the pure logic of the sample app: the payloads it builds and the
//  catalogs its screens are driven from. Anything touching the SDK singleton is
//  deliberately left out — `RelatedDigital.initialize` can only run once per
//  process, which makes it a poor fit for unit tests.
//
//  Note: this bundle is not a target in RelatedDigitalExample.xcodeproj. Add
//  one in Xcode (File → New → Target → Unit Testing Bundle) to run these.
//

import XCTest
@testable import RelatedDigitalExample
@testable import RelatedDigitalIOS

final class RelatedDigitalExampleTests: XCTestCase {

    // MARK: - Sample data

    func testSampleBasketProducesDistinctProductCodes() {
        for _ in 0..<50 {
            let basket = SampleBasket.random()
            XCTAssertNotEqual(basket.productCode1, basket.productCode2)
        }
    }

    func testLineTotalsMultiplyPriceByQuantity() {
        let basket = SampleBasket.random()
        XCTAssertEqual(basket.lineTotal1, (basket.price1 * Double(basket.quantity1)).priceString)
        XCTAssertEqual(basket.lineTotal2, (basket.price2 * Double(basket.quantity2)).priceString)
    }

    func testPriceStringUsesDotSeparatorAndTwoDecimals() {
        XCTAssertEqual(1234.5.priceString, "1234.50")
        XCTAssertEqual(0.999.priceString, "1.00")
    }

    // MARK: - Analytics catalog

    func testAnalyticsCatalogHasUniqueIdentifiers() {
        let ids = AnalyticsCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryAnalyticsGroupIsPopulated() {
        for group in AnalyticsAction.Group.allCases {
            XCTAssertFalse(AnalyticsCatalog.actions(in: group).isEmpty,
                           "\(group.rawValue) has no actions")
        }
    }

    @MainActor
    func testProductViewCarriesTheRequiredPanelFields() throws {
        let action = try XCTUnwrap(AnalyticsCatalog.all.first { $0.id == "product-view" })
        let basket = SampleBasket.random()
        let properties = action.properties(AppConfig.shared, basket, "token")

        XCTAssertEqual(properties["OM.pv"], basket.productCode1)
        XCTAssertEqual(properties["OM.ppr"], basket.price1.priceString)
        XCTAssertEqual(properties["OM.inv"], "\(basket.inventory)")
    }

    @MainActor
    func testAddToCartAndPurchaseSharePriceFormatting() throws {
        let basket = SampleBasket.random()
        let cart = try XCTUnwrap(AnalyticsCatalog.all.first { $0.id == "add-to-cart" })
        let purchase = try XCTUnwrap(AnalyticsCatalog.all.first { $0.id == "purchase" })

        let expected = "\(basket.lineTotal1);\(basket.lineTotal2)"
        XCTAssertEqual(cart.properties(AppConfig.shared, basket, "token")["OM.ppr"], expected)
        XCTAssertEqual(purchase.properties(AppConfig.shared, basket, "token")["OM.ppr"], expected)
    }

    // MARK: - Targeting catalog

    func testTargetingCatalogHasUniqueEntries() {
        let ids = TargetingCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testProductStatNotifierCarriesAProductCode() throws {
        let action = try XCTUnwrap(TargetingCatalog.all.first {
            $0.queryString == RDInAppNotificationType.productStatNotifier.rawValue
        })
        XCTAssertNotNil(action.extraProperties["OM.pv"])
    }

    func testEveryTargetingCategoryIsPopulated() {
        for category in TargetingAction.Category.allCases {
            XCTAssertFalse(TargetingCatalog.all.filter { $0.category == category }.isEmpty,
                           "\(category.rawValue) has no actions")
        }
    }

    // MARK: - Environments

    func testTestEnvironmentUsesItsOwnCredentials() {
        let test = SDKEnvironment.test.defaults
        XCTAssertEqual(test.organizationId, "394A48556A2F76466136733D")
        XCTAssertEqual(test.profileId, "75763259366A3345686E303D")
        XCTAssertEqual(test.dataSource, "mhrp")
    }

    func testProductionCredentialsMatchTheSDKConstants() {
        // Guards against `UrlConstant.setTest()` having mutated the shared
        // instance before these are read.
        let production = SDKEnvironment.production.defaults
        XCTAssertEqual(production.organizationId, "676D325830564761676D453D")
        XCTAssertEqual(production.profileId, "356467332F6533766975593D")
        XCTAssertEqual(production.dataSource, "visistore")
    }

    func testEnvironmentsNeverShareCredentials() {
        XCTAssertNotEqual(SDKEnvironment.production.defaults, SDKEnvironment.test.defaults)
        XCTAssertNotEqual(SDKEnvironment.production.host, SDKEnvironment.test.host)
    }

    // MARK: - Console

    func testPayloadRenderingIsSortedAndStable() {
        XCTAssertEqual(EventLog.render(["b": "2", "a": "1", "c": "3"]), "a = 1\nb = 2\nc = 3")
    }

    @MainActor
    func testConsoleRecordsNewestFirstAndClears() {
        let log = EventLog.shared
        log.clear()

        log.call("customEvent(\"Test\")", channel: .analytics, payload: ["OM.pv": "1"])
        log.failure("boom", channel: .push, detail: "details")

        XCTAssertEqual(log.entries.count, 2)
        XCTAssertEqual(log.entries.first?.kind, .failure)
        XCTAssertTrue(log.exportText.contains("customEvent"))

        log.clear()
        XCTAssertTrue(log.entries.isEmpty)
    }
}
