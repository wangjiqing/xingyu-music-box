import AppKit
import SwiftUI

@main
struct XingyuMusicBoxMacApp: App {
    @StateObject private var viewModel = MacPlayerViewModel()
    @StateObject private var themeManager = MacThemeManager()

    var body: some Scene {
        WindowGroup("星语音乐盒") {
            MacRootView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .frame(minWidth: MacLayoutMetrics.minimumWindowSize.width, minHeight: MacLayoutMetrics.minimumWindowSize.height)
                .background(MacWindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("播放") {
                Button(viewModel.isPlaying ? "暂停" : "播放") {
                    viewModel.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("上一首") {
                    viewModel.previous()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Button("下一首") {
                    viewModel.next()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
            }
        }

        MenuBarExtra {
            MacMenuBarPlayerPanel(viewModel: viewModel)
                .environmentObject(themeManager)
        } label: {
            MacMenuBarStatusLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MacMenuBarStatusLabel: View {
    @ObservedObject var viewModel: MacPlayerViewModel

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "music.note")
                .symbolVariant(.circle.fill)
            if viewModel.isPlaying {
                Text(viewModel.menuBarDisplayText)
                    .lineLimit(1)
            }
        }
        .help(viewModel.menuBarDisplayText)
    }
}

private struct MacMenuBarPlayerPanel: View {
    @ObservedObject var viewModel: MacPlayerViewModel
    @EnvironmentObject private var themeManager: MacThemeManager

    private var track: MacTrackItem? {
        viewModel.currentTrack ?? viewModel.selectedTrack
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "music.note")
                    .symbolVariant(.circle.fill)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(themeManager.currentTheme.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(track?.title ?? "星语音乐盒")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(track?.artist ?? "未播放")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }

            Text(viewModel.menuBarDisplayText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewModel.isPlaying ? themeManager.currentTheme.accent : .secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 18) {
                menuBarButton(systemImage: "backward.end.fill", help: "上一首", isEnabled: track != nil) {
                    viewModel.previous()
                }

                menuBarButton(systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill", help: viewModel.isPlaying ? "暂停" : "播放", isEnabled: track != nil) {
                    viewModel.togglePlayback()
                }

                menuBarButton(systemImage: "forward.end.fill", help: "下一首", isEnabled: track != nil) {
                    viewModel.next()
                }

                menuBarButton(systemImage: viewModel.isFavorite(track) ? "heart.fill" : "heart", help: viewModel.isFavorite(track) ? "取消喜欢" : "标记喜欢", isEnabled: track != nil) {
                    viewModel.toggleFavorite(track)
                }
                .foregroundStyle(viewModel.isFavorite(track) ? Color(red: 1.0, green: 0.42, blue: 0.28) : themeManager.currentTheme.muted)
            }
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)

            Divider()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            } label: {
                Label("打开星语音乐盒", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 286)
    }

    private func menuBarButton(
        systemImage: String,
        help: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.34)
        .help(help)
    }
}

private struct MacWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureWindow(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(for: nsView)
        }
    }

    private func configureWindow(for view: NSView) {
        guard let window = view.window else { return }
        window.title = "星语音乐盒"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = false
        window.minSize = MacLayoutMetrics.minimumWindowSize
        window.toolbar = nil
    }
}
