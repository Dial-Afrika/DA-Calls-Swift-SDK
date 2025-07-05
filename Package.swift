// swift-tools-version:5.7
// DACalls - Swift package for VoIP call handling
import PackageDescription

let package = Package(
    name: "DACalls",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "DACalls",
            targets: ["DACalls"]
        ),
    ],
    dependencies: [
        //        .package(url: "https://gitlab.linphone.org/BC/public/linphone-sdk-swift-ios.git", branch: "novideo/stable")
        .package(url: "https://gitlab.linphone.org/BC/public/linphone-sdk-swift-ios.git", from: "5.4.0"),
    ],
    targets: [
        .target(
            name: "DACalls",
            dependencies: [
                .product(name: "linphonesw", package: "linphone-sdk-swift-ios"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DACallsTests",
            dependencies: ["DACalls"]
        ),
    ]
)
