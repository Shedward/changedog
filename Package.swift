// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ChangeDog",
    dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "ChangeDog",
            dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		),
        .testTarget(
            name: "ChangeDogTests",
            dependencies: ["ChangeDog"]
		),
    ]
)
