// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChangeDog",
    dependencies: [
    ],
    targets: [
        .target(
            name: "ChangeDog",
            dependencies: []),
        .testTarget(
            name: "ChangeDogTests",
            dependencies: ["ChangeDog"]),
    ]
)
