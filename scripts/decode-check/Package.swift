// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DecodeCheck",
    platforms: [.macOS(.v13)],
    targets: [
        // CI copies Shared/*.swift + main.swift into Sources/ before running.
        .executableTarget(name: "DecodeCheck", path: "Sources")
    ]
)