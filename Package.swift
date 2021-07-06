// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RelatedDigitalIOS",
    platforms: [
      .iOS(.v10)
    ],
    products: [
        .library(
            name: "RelatedDigitalIOS",
            targets: ["RelatedDigitalIOS"]),
    ],
    targets: [
        .target(
            name: "RelatedDigitalIOS",
            path:"Sources",
            resources: [.process("Assets")])
    ]
)
