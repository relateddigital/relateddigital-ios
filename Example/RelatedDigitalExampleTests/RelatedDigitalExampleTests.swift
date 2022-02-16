//
//  RelatedDigitalExampleTests.swift
//  RelatedDigitalExampleTests
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import XCTest

@testable import RelatedDigitalExample
@testable import RelatedDigitalIOS

class RelatedDigitalExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRelatedDigitalInitializeInAppNotificationsEnabledFalse() throws {
        RelatedDigital.initialize(organizationId: "oid", profileId: "pid", dataSource: "ds", launchOptions: nil)
        XCTAssertFalse(RelatedDigital.inAppNotificationsEnabled)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
