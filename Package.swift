// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoSelectAndCrop",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PhotoSelectAndCrop",
            targets: ["PhotoSelectAndCrop"]),
    ],
    targets: [
        .target(
            name: "PhotoSelectAndCrop",
            path: "Sources",
            resources: [.process("PhotoSelectAndCrop/Resources")]),
    ]
)
