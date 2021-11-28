// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoSelectAndCrop",
    defaultLocalization: "en",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "PhotoSelectAndCrop",
            targets: ["PhotoSelectAndCrop"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PhotoSelectAndCrop",
            dependencies: [],
            path: "Sources",
            resources: [.process("PhotoSelectAndCrop/Resources")]),
    ]
)
