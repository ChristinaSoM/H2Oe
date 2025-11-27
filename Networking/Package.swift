// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// https://fatbobman.com/en/posts/practical-swiftdata-building-swiftui-applications-with-modern-approaches/

import PackageDescription

let package = Package(
    name: "Networking",
    
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        ),
    ],
    
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
          name: "Networking",
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
        ),
    ]
)
