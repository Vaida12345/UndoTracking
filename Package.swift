// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UndoTracking",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ], products: [
        .library(name: "UndoTracking", targets: ["UndoTracking"]),
    ], targets: [
        .target(name: "UndoTracking", path: "Sources"),
        .testTarget(name: "Tests", dependencies: ["UndoTracking"], path: "Tests")
    ]
)
