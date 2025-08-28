// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceRecognitionDlib",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FaceRecognitionDlib",
            targets: ["FaceRecognitionDlib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/AppliedRecognition/Face-Detection-RetinaFace-Apple", .upToNextMajor(from: "1.0.4"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DlibLandmarks",
            path: "Sources/DlibLandmarks",
            resources: [
                .copy("Resources")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("DLIB_NO_GUI_SUPPORT"),
                .define("DLIB_USE_BLAS", to: "0"),
                .define("DLIB_USE_LAPACK", to: "0"),
            ],
            cxxSettings: [
                .headerSearchPath("../../Vendor/dlib-src"),  // or dlib-min
//                .unsafeFlags(["-std=c++17","-ffunction-sections","-fdata-sections"]),
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "FaceRecognitionDlib",
            dependencies: [
                "DlibLandmarks",
                .product(name: "VerIDCommonTypes", package: "Ver-ID-Common-Types-Apple")
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "FaceRecognitionDlibTests",
            dependencies: [
                "FaceRecognitionDlib",
                .product(name: "FaceDetectionRetinaFace", package: "Face-Detection-RetinaFace-Apple")
            ],
            resources: [
                .process("Resources")
            ]),
    ],
    cxxLanguageStandard: .cxx17
)
