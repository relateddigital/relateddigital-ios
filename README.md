![RelatedDigital Logo](/Screenshots/relateddigital.png)

[![Actions Status](https://github.com/relateddigital/relateddigital-ios/workflows/CI/badge.svg)](https://github.com/relateddigital/relateddigital-ios/actions)
[![Version](https://img.shields.io/cocoapods/v/RelatedDigitalIOS.svg?style=flat)](https://cocoapods.org/pods/RelatedDigitalIOS)
[![License](https://img.shields.io/cocoapods/l/RelatedDigitalIOS.svg?style=flat)](https://cocoapods.org/pods/RelatedDigitalIOS)
[![Platform](https://img.shields.io/cocoapods/p/RelatedDigitalIOS.svg?style=flat)](https://cocoapods.org/pods/RelatedDigitalIOS)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

# RelatedDigital iOS SDK

## Installation

### CocoaPods

```ruby
pod 'RelatedDigitalIOS'
```

## Integration

### Option 1: RelatedDigital-Info.plist (Recommended)

1. Add `RelatedDigital-Info.plist` to your project bundle.
2. Fill in your credentials:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>OrganizationId</key>
        <string>YOUR_ORG_ID</string>
        <key>ProfileId</key>
        <string>YOUR_PROFILE_ID</string>
        <key>DataSource</key>
        <string>YOUR_DATA_SOURCE</string>
        <key>AppAlias</key>
        <string>YOUR_APP_ALIAS</string>
        <key>EnablePushNotifications</key>
        <true/>
    </dict>
    </plist>
    ```
3. Initialize in `AppDelegate`:

```swift
import RelatedDigitalIOS

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    RelatedDigital.start(launchOptions: launchOptions)
    return true
}
```

That's it! Push tokens and notifications are handled automatically.

### Option 2: Config Object

```swift
let config = RDConfig(
    organizationId: "ORG_ID",
    profileId: "PROFILE_ID",
    dataSource: "DATA_SOURCE",
    appAlias: "APP_ALIAS"
)
RelatedDigital.start(with: config, launchOptions: launchOptions)
```

## Notification Service Extension

Create a Notification Service Extension target and inherit from `RDNotificationService`:

```swift
import RelatedDigitalIOS

class NotificationService: RDNotificationService {
    // No extra code needed!
}
```
