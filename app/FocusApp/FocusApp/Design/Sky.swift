import SwiftUI
import FocusModel

/// The backdrop follows the person's own focus window — dawn before and while it warms up, daylight
/// during best focus, dusk as focus lightens, night after — as a faint tint over the frosted plate.
enum SkyPhase: String, CaseIterable, Sendable {
    case dawn, day, dusk, night

    static func at(_ date: Date, window: FocusWindow?) -> SkyPhase {
        guard let window else {
            let hour = Calendar.current.component(.hour, from: date)
            return hour < 10 ? .dawn : hour < 17 ? .day : hour < 20 ? .dusk : .night
        }
        switch window.zone(at: date) {
        case .before, .warmUp: return .dawn
        case .bestFocus: return .day
        case .lighterFocus: return .dusk
        case .after: return .night
        }
    }

    /// A soft-light wash over the plate: rose at dawn, champagne by day, mauve at dusk, cool at night.
    var tint: Color {
        switch self {
        case .dawn: Color(hex: "E7A99A")
        case .day: Color(hex: "E3C48E")
        case .dusk: Color(hex: "A98FB5")
        case .night: Color(hex: "7F8FA8")
        }
    }
}

/// Frosted glass over architecture. Each theme has its own photograph, pre-blurred until only its
/// light and dark masses remain (Assets: BackdropLight / BackdropDark, made by
/// scratchpad/backdrop/make.swift with the frost tuned so every text colour keeps ≥ 4.5:1). On top:
/// the phase wash, a diagonal sheen like light on a pane, and fine grain — the "glass" in the blur.
struct SkyBackground: View {
    var phase: SkyPhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.motionIsCalm) private var calm
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(Customisation.self) private var custom
    @State private var drift = false

    private var backdrop: Backdrop { scheme == .dark ? custom.settings.darkBackdrop : custom.settings.lightBackdrop }

    private var plate: ImageResource? {
        switch (backdrop, scheme == .dark) {
        case (.facade, true): .backdropDark
        case (.facade, false): .facadeLight
        case (.baroque, true): .baroqueDark
        case (.baroque, false): .backdropLight
        case (.plain, _): nil
        }
    }

    var body: some View {
        let dark = scheme == .dark
        let s = custom.settings
        ZStack {
            if let plate {
                Color.clear.overlay {
                    Image(plate)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: s.blur, opaque: true)
                        .scaleEffect(drift ? 1.08 : 1.03)
                        .offset(y: drift ? -12 : 0)
                }
                .clipped()
            } else {
                Color(hex: dark ? "1C1917" : "EFE8DE")
            }
            (dark ? Color.black : Color.white).opacity(s.frost * 0.3)
            phase.tint
                .blendMode(.softLight)
                .opacity(dark ? 0.16 : 0.22)
            LinearGradient(stops: [
                .init(color: .white.opacity(dark ? 0.035 : 0.16), location: 0),
                .init(color: .white.opacity(0), location: 0.42),
                .init(color: .white.opacity(0), location: 0.7),
                .init(color: .white.opacity(dark ? 0.02 : 0.08), location: 1),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .blendMode(dark ? .plusLighter : .softLight)
            // Dark mode sits half as bright by default (Customise, Look, Darkness).
            if dark { Color.black.opacity(s.darkness) }
            if !reduceTransparency {
                Image(uiImage: GrainTexture.tile)
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity((dark ? 0.16 : 0.12) * s.grain)
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(calm ? nil : .smooth(duration: 1.6), value: phase)
        .onAppear {
            guard !calm else { return }
            withAnimation(.easeInOut(duration: 24).repeatForever(autoreverses: true)) { drift = true }
        }
        .accessibilityHidden(true)
    }
}

extension Color {
    nonisolated init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}


/// Film grain without a GPU shader: one small noise tile, generated once and tiled over the sky.
/// (A Metal `[[stitchable]]` version lives in app/FocusApp/Optional/Grain.metal for builds with the
/// Metal toolchain installed; the tile looks the same at a fraction of the setup.)
enum GrainTexture {
    static let tile: UIImage = {
        let size = 128
        var rng = Seeded(seed: 41)
        let pixels = (0..<(size * size)).map { _ in UInt8(truncatingIfNeeded: rng.next() >> 56) }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let image = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: size,
                            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        return UIImage(cgImage: image, scale: 2, orientation: .up)
    }()
}
