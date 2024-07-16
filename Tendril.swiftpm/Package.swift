// swift-tools-version: 5.8

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Tendril",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Tendril",
            targets: ["AppModule"],
            bundleIdentifier: "com.gdb.tendril",
            teamIdentifier: "9VV558X8J3",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .boat),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            appCategory: .productivity
        )
    ],
    dependencies: [
        .package(url: "https://github.com/gdbing/SwiftChatGPT", "1.1.0"..<"2.0.0"),
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", "1.4.0"..<"2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "SwiftChatGPT", package: "SwiftChatGPT"),
                .product(name: "SwiftAnthropic", package: "swiftanthropic")
            ],
            path: ".",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)