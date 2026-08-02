// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MacroPilot",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "MacroPilot", targets: ["MacroPilot"])
  ],
  targets: [
    .executableTarget(name: "MacroPilot"),
    .testTarget(name: "MacroPilotTests", dependencies: ["MacroPilot"])
  ]
)
