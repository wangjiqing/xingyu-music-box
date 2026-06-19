import SwiftUI

// MARK: - Phonograph View (留声机唱片播放效果)

/// A phonograph-style now-playing view with spinning record and animated tonearm.
/// Mirrors the macOS `MacPhonographView` using iOS-compatible `UIImage`.
struct PhonographView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let coverImage: UIImage?
    let isPlaying: Bool

    private let designCanvasSize = CGSize(width: 500, height: 400)
    private let visualBoundsSize = CGSize(width: 450.5, height: 381)

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / visualBoundsSize.width,
                proxy.size.height / visualBoundsSize.height
            )

            designCanvas
                .frame(width: designCanvasSize.width, height: designCanvasSize.height)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(
                    width: visualBoundsSize.width * scale,
                    height: visualBoundsSize.height * scale,
                    alignment: .topLeading
                )
                .clipped()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
    }

    private var designCanvas: some View {
        ZStack(alignment: .topLeading) {
            bundleImage(named: AppTheme.current.phonographBaseName)
                .frame(width: 500, height: 400)

            SpinningRecordView(
                coverImage: coverImage,
                isPlaying: isPlaying
            )
            .frame(width: 270, height: 270)
            .offset(x: 25, y: 15)

            TonearmView(isPlaying: isPlaying)
                .frame(width: 65, height: 300)
                .offset(x: 254, y: -24)
        }
    }

    @ViewBuilder
    private func bundleImage(named name: String) -> some View {
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "NowPlaying"
        ),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.white.opacity(0.12))
        }
    }
}

// MARK: - Tonearm (唱臂)

private struct TonearmView: View {
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let wobble = isPlaying ? sin(context.date.timeIntervalSinceReferenceDate * 1.05) * 0.12 : 0
            let angle = (isPlaying ? 8.2 : -6.0) + wobble

            bundleImage(named: AppTheme.current.phonographArmName)
                .frame(width: 65, height: 300)
                .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.604, y: 0.192))
                .animation(.spring(response: 0.92, dampingFraction: 0.92), value: isPlaying)
        }
    }

    @ViewBuilder
    private func bundleImage(named name: String) -> some View {
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "NowPlaying"
        ),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.clear)
        }
    }
}

// MARK: - Spinning Record (旋转唱片)

private struct SpinningRecordView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var baseAngle: Double = 0
    @State private var playStartDate: Date?

    let coverImage: UIImage?
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let angle = currentAngle(at: context.date)

            ZStack {
                // Shadow layer
                bundleImage(named: AppTheme.current.phonographShadowName)
                    .frame(width: 294, height: 294)
                    .opacity(AppTheme.current.phonographShadowOpacity)

                // Chassis + artwork + highlight
                ZStack {
                    bundleImage(named: AppTheme.current.phonographChassisName)
                        .frame(width: 270, height: 270)

                    // Artwork in center
                    artworkCircle
                        .frame(width: 142, height: 142)
                        .overlay {
                            Circle()
                                .stroke(XYStyle.accent.opacity(0.58), lineWidth: 8)
                        }

                    bundleImage(named: AppTheme.current.phonographHighlightName)
                        .frame(width: 270, height: 270)
                        .opacity(0.94)

                    // Center spindle
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, y: 1)
                }
                .rotationEffect(.degrees(angle.truncatingRemainder(dividingBy: 360)))
            }
        }
        .onAppear {
            if isPlaying, playStartDate == nil {
                playStartDate = Date()
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                playStartDate = Date()
            } else {
                baseAngle = currentAngle(at: Date()).truncatingRemainder(dividingBy: 360)
                playStartDate = nil
            }
        }
    }

    @ViewBuilder
    private var artworkCircle: some View {
        if let coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [XYStyle.accent.opacity(0.86), XYStyle.panelDark.opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(XYStyle.text.opacity(0.72))
                }
        }
    }

    private func currentAngle(at date: Date) -> Double {
        guard isPlaying, let playStartDate else {
            return baseAngle
        }
        return baseAngle + date.timeIntervalSince(playStartDate) * 36
    }

    @ViewBuilder
    private func bundleImage(named name: String) -> some View {
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "NowPlaying"
        ),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.clear)
        }
    }
}
