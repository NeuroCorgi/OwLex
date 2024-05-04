// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "OwLex",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "OwLex",
            targets: ["OwLex"]
        ),
        .executable(
            name: "OwLexClient",
            targets: ["OwLexClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "OwLexMacros",
            dependencies: [
              .target(name: "Regex"),
              .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
              .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "Regex"),
        .target(name: "OwLex", dependencies: ["OwLexMacros"]),
        .executableTarget(
          name: "OwLexClient",
          dependencies: ["OwLex", "Regex"],
          swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiteral")]
        ),

        .testTarget(
            name: "OwLexTests",
            dependencies: [
                "OwLexMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
          name: "RegexTests",
          dependencies: [
            "Regex"
          ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(.enableUpcomingFeature("BareSlashRegexLiteral"))
    target.swiftSettings?.append(.unsafeFlags(["-enable-bare-slash-regex"]))
}
