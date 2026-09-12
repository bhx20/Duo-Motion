// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "duo_motion",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "duo-motion", targets: ["duo_motion"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "duo_motion",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // Empty arrays throughout: Core Motion is not a required-reason
                // API and nothing here is collected. Shipped regardless, since
                // an absent manifest and one that declares nothing read the
                // same to a human and differently to App Store review.
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
