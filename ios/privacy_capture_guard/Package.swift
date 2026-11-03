// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "privacy_capture_guard",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "privacy-capture-guard", targets: ["privacy_capture_guard"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "privacy_capture_guard",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
