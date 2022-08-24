// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NewRelic",
    platforms: [
        .iOS(.v9), .macOS(.v10_14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NewRelic",
            targets: ["NewRelic"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(name: "NewRelic",
                      url: "https://download.newrelic.com/ios_agent/NewRelic_XCFramework_Agent_7.3.8.zip",
                      checksum: "4394f5d57ced040ff2a883958bebd66c884804ebac8d6b21fea8215fe1897df1")
    ]
)

