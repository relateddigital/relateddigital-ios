//
//  PushKey.swift
//  RelatedDigitalIOS
//
//  Created by Egemen on 10.02.2022.
//

import Foundation

class PushKey {
    internal static let appAliasNotProvidedMessage = """
                    appAlias not provided. Please use RelatedDigital.configure(::) function first.
                    For more information visit https://github.com/relateddigital/relateddigital-ios
                    """
    
    internal static let tokenKey = "EURO_TOKEN_KEY"
    internal static let registerKey = "EURO_REGISTER_KEY"
    internal static let euroLastMessageKey = "EURO_LAST_MESSAGE_KEY"
    internal static let identifierForVendorKey = "EURO_IDENTIFIER_FOR_VENDOR_KEY"
    internal static let euroReceivedStatus = "D"
    internal static let euroReadStatus = "O"
    internal static let isBadgeCustom = "EMisBadgeCustom"
    internal static let badgeCount = "EMbadgeCount"
    internal static let userDefaultSuiteKey =  "group.relateddigital.euromsg" // TODO: bu sabit olmamalı, müşteri set etmeli.
    internal static let userAgent = "user-agent"
    
    internal static let timeoutInterval = 30
    internal static let prodBaseUrl = ".euromsg.com"
    
    
    internal static let payloadDayThreshold = 30
    internal static let euroPayloadsKey = "EURO_PAYLOADS_KEY"
    internal static let appGroupNameDefaultPrefix = "group"
    internal static let appGroupNameDefaultSuffix = "relateddigital"
    
    internal static let euroReadPushIdListKey = "EURO_READ_PUSHID_LIST_KEY"
    
    
    internal static let euroLastSuccessfulSubscriptionDateKey = "EURO_LAST_SUCCESSFUL_SUBSCRIPTION_DATE_KEY"
    internal static let euroLastSuccessfulSubscriptionKey = "EURO_LAST_SUCCESSFUL_SUBSCRIPTION_KEY"
    internal static let threeDaysInSeconds = 259200 // 3 days
    
    internal static let graylogLogLevelError = "e"
    internal static let graylogLogLevelWarning = "w"
    
    
}
