// swift-tools-version: 6.2
import PackageDescription

// Target graph is the safety architecture (docs/system-design.md §2.1):
//   FocusModel        shared value types + read-only dose protocol
//   FocusMedication   the ONLY code that can write dose events (depends on FocusModel)
//   FocusPlanning     focus-window learning, scheduler, safety gate (depends on FocusModel only)
//   FocusSync         the backend client: API, sessions, device proofs, end-to-end encryption
//   FocusGlance       what the app shares with its extensions (Live Activity attributes)
// FocusPlanning cannot import FocusMedication, so no scheduler, learner or AI path can
// create, move or suggest a dose — the compiler enforces rule 1–3 of spec §8.2.
let package = Package(
    name: "FocusCore",
    platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26)],
    products: [
        .library(name: "FocusModel", targets: ["FocusModel"]),
        .library(name: "FocusMedication", targets: ["FocusMedication"]),
        .library(name: "FocusPlanning", targets: ["FocusPlanning"]),
        .library(name: "FocusSync", targets: ["FocusSync"]),
        .library(name: "FocusGlance", targets: ["FocusGlance"]),
    ],
    targets: [
        .target(name: "FocusModel"),
        .target(name: "FocusMedication", dependencies: ["FocusModel"]),
        .target(name: "FocusPlanning", dependencies: ["FocusModel"]),
        .target(name: "FocusSync"),
        .target(name: "FocusGlance"),
        .testTarget(name: "FocusMedicationTests", dependencies: ["FocusMedication"]),
        .testTarget(name: "FocusPlanningTests", dependencies: ["FocusPlanning"]),
        .testTarget(name: "FocusSyncTests", dependencies: ["FocusSync"]),
    ]
)
