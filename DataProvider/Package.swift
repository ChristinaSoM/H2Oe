// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// https://fatbobman.com/en/posts/practical-swiftdata-building-swiftui-applications-with-modern-approaches/

import PackageDescription

let package = Package(
    name: "DataProvider",
    
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    
    products: [
        .library(
            name: "DataProvider",
            targets: ["DataProvider"]
        ),
    ],
    
    targets: [
    
        .target(
          name: "DataProvider",
          swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
          ]
        ),
        .testTarget(
            name: "DataProviderTests",
            dependencies: ["DataProvider"],
        ),
    ]
)
