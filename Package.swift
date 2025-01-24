// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PhotoZoomAnimator",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "PhotoZoomAnimator",
            targets: ["PhotoZoomAnimator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "PhotoZoomAnimator",
            dependencies: ["SnapKit"],
            path: "PhotoZoomAnimator")
    ]
)
