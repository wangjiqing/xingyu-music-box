import SwiftUI

struct ProgressSliderView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var editingValue: Double = 0
    @State private var isEditing = false

    private var displayTime: Double {
        isEditing ? editingValue : currentTime
    }

    private var safeDuration: Double {
        max(duration, 1)
    }

    private var canSeek: Bool {
        duration.isFinite && duration > 0
    }

    private var progress: CGFloat {
        CGFloat(min(max(displayTime / safeDuration, 0), 1))
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text(formatTime(displayTime))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(width: 64, alignment: .leading)
                Spacer()
                Text(duration > 0 ? formatTime(duration) : "--:--")
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(width: 64, alignment: .trailing)
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(XYStyle.text)

            GeometryReader { proxy in
                let width = proxy.size.width
                let knobSize: CGFloat = 16
                let trackHeight: CGFloat = 5
                let filledWidth = max(knobSize / 2, width * progress)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(XYStyle.controlBackground)
                        .frame(height: trackHeight)

                    Capsule()
                        .fill(XYStyle.accent)
                        .frame(width: filledWidth, height: trackHeight)
                        .shadow(color: XYStyle.accent.opacity(0.75), radius: 8)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [XYStyle.accent, XYStyle.accent, XYStyle.accent],
                                center: .topLeading,
                                startRadius: 1,
                                endRadius: 16
                            )
                        )
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: XYStyle.accent.opacity(0.9), radius: 9)
                        .overlay {
                            Circle().stroke(XYStyle.accent.opacity(0.6), lineWidth: 1)
                        }
                        .offset(x: min(max(width * progress - knobSize / 2, 0), width - knobSize))
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard canSeek else { return }
                            isEditing = true
                            editingValue = seconds(for: value.location.x, width: width)
                        }
                        .onEnded { value in
                            guard canSeek else { return }
                            let target = seconds(for: value.location.x, width: width)
                            editingValue = target
                            onSeek(target)
                            isEditing = false
                        }
                )
            }
            .frame(height: 24)
            .opacity(canSeek ? 1 : 0.45)
            .allowsHitTesting(canSeek)
        }
        .padding(.horizontal, 24)
    }

    private func seconds(for locationX: CGFloat, width: CGFloat) -> Double {
        guard width > 0, canSeek else { return 0 }
        let ratio = min(max(locationX / width, 0), 1)
        return min(max(Double(ratio) * duration, 0), duration)
    }

    private func formatTime(_ value: Double) -> String {
        let seconds = max(0, Int(value.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", remainingSeconds))"
        }
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}
