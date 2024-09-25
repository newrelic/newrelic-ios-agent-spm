// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NewRelic",
    platforms: [
        .iOS(.v9), .macOS(.v10_14), .tvOS(.v9), .watchOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NewRelic",
            targets: ["NewRelicPackage", "NewRelic"]),
    ],
    targets: [
        .target(
            name: "NewRelicPackage",
            dependencies: []),
        .binaryTarget(name: "NewRelic",
                      url: "https://download.newrelic.com/ios_agent/NewRelic_XCFramework_Agent_7.5.2.zip",
                      checksum: "650ef2196d5af8118c64f3485b0518841164e617eab889e61f351c24890dd43c")
    ]
)

